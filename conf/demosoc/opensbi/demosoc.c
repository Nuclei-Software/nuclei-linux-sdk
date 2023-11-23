/*
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Copyright (c) 2023 Nuclei System Technology or its affiliates.
 *
 * Authors:
 *   Huaqi Fang <hqfang@nucleisys.com>
 */

#include <platform_override.h>
#include <sbi/riscv_asm.h>
#include <sbi_utils/fdt/fdt_helper.h>
#include <sbi_utils/fdt/fdt_fixup.h>

typedef struct {
	uint32_t INPUT_VAL;
	uint32_t INPUT_EN;
	uint32_t OUTPUT_EN;
	uint32_t OUTPUT_VAL;
	uint32_t PULLUP_EN;
	uint32_t DRIVE;
	uint32_t RISE_IE;
	uint32_t RISE_IP;
	uint32_t FALL_IE;
	uint32_t FALL_IP;
	uint32_t HIGH_IE;
	uint32_t HIGH_IP;
	uint32_t LOW_IE;
	uint32_t LOW_IP;
	uint32_t IOF_EN;
	uint32_t IOF_SEL;
	uint32_t OUTPUT_XOR;
} GPIO_TypeDef;

typedef enum iof_func {
	IOF_SEL_GPIO = 0,
	IOF_SEL_0 = 1,
	IOF_SEL_1 = 2
} IOF_FUNC;

#ifndef __RARELY
	#define __RARELY(exp)					__builtin_expect((exp), 0)
#endif

#define DEMOSOC_PERIPH_BASE					(0x10000000UL)						/*!< (Peripheral) Base Address */
#define DEMOSOC_GPIO_BASE					(DEMOSOC_PERIPH_BASE + 0x12000)		/*!< (GPIO) Base Address */
#define GPIO								((GPIO_TypeDef *) DEMOSOC_GPIO_BASE)

#define NUCLEI_GPIO_IOF_UART0_MASK			0x00030000
#define NUCLEI_GPIO_IOF_UART1_MASK			0x03000000
#define NUCLEI_GPIO_IOF_QSPI2_MASK			0xFC000000

#define NUCLEI_GPIO_INPUT_EN_UART0_MASK		0x00010000
#define NUCLEI_GPIO_INPUT_EN_UART1_MASK		0x01000000
#define NUCLEI_GPIO_INPUT_EN_QSPI2_MASK		0x10000000

#define NUCLEI_GPIO_OUTPUT_EN_UART0_MASK	0x00020000
#define NUCLEI_GPIO_OUTPUT_EN_UART1_MASK	0x02000000
#define NUCLEI_GPIO_OUTPUT_EN_QSPI2_MASK	0xEC000000

#define NUCLEI_GPIO_IOF_MASK				(NUCLEI_GPIO_IOF_UART0_MASK | \
                            NUCLEI_GPIO_IOF_UART1_MASK | NUCLEI_GPIO_IOF_QSPI2_MASK)

#define NUCLEI_GPIO_INPUT_EN_MASK			(NUCLEI_GPIO_INPUT_EN_UART0_MASK | \
                            NUCLEI_GPIO_INPUT_EN_UART1_MASK | NUCLEI_GPIO_INPUT_EN_QSPI2_MASK)

#define NUCLEI_GPIO_OUTPUT_EN_MASK			(NUCLEI_GPIO_OUTPUT_EN_UART0_MASK | \
                            NUCLEI_GPIO_OUTPUT_EN_UART1_MASK | NUCLEI_GPIO_OUTPUT_EN_QSPI2_MASK)

static const struct fdt_match nuclei_demosoc_match[] = {
	{ .compatible = "nuclei,demosoc" },
	{ .compatible = "nuclei,demo-soc" },
	{ },
};

static int32_t gpio_iof_config(GPIO_TypeDef* gpio, uint32_t mask, IOF_FUNC func)
{
	if (__RARELY(gpio == NULL)) {
		return -1;
	}
	switch (func) {
		case IOF_SEL_GPIO:
			gpio->IOF_EN &= ~mask;
			break;
		case IOF_SEL_0:
			gpio->IOF_SEL &= ~mask;
			gpio->IOF_EN |= mask;
			break;
		case IOF_SEL_1:
			gpio->IOF_SEL |= mask;
			gpio->IOF_EN |= mask;
			break;
		default:
			break;
	}
	return 0;
}

static int32_t gpio_enable_output(GPIO_TypeDef* gpio, uint32_t mask)
{
	if (__RARELY(gpio == NULL)) {
		return -1;
	}
	gpio->OUTPUT_EN |= mask;
	gpio->INPUT_EN &= ~mask;
	return 0;
}

static int32_t gpio_enable_input(GPIO_TypeDef* gpio, uint32_t mask)
{
	if (__RARELY(gpio == NULL)) {
		return -1;
	}
	gpio->INPUT_EN |= mask;
	gpio->OUTPUT_EN &= ~mask;
	return 0;
}

static int nuclei_demosoc_early_init(bool cold_boot,
				   const struct fdt_match *match)
{
	if (cold_boot) {
		// Enable pinmux for uart0/1 qspi2
		gpio_iof_config(GPIO, NUCLEI_GPIO_IOF_MASK, IOF_SEL_0);
		gpio_enable_output(GPIO, NUCLEI_GPIO_OUTPUT_EN_MASK);
		gpio_enable_input(GPIO, NUCLEI_GPIO_INPUT_EN_MASK);
	}

	return 0;
}

static int nuclei_demosoc_final_init(bool cold_boot,
				   const struct fdt_match *match)
{
	if (cold_boot) { // Add cold boot initial steps
	}

	// Check mcfg_info.tee to see whether tee present
	if (csr_read(0xfc2) & 0x1) {
		// Enable U-Mode to access all regions by setting spmpcfg0 and spmpaddr0
		csr_write(0x1a0, 0x1f);
		csr_write(0x1b0, 0xffffffff);
	}

	return 0;
}

const struct platform_override nuclei_demosoc = {
	.match_table = nuclei_demosoc_match,
	.early_init = nuclei_demosoc_early_init,
	.final_init = nuclei_demosoc_final_init,
};

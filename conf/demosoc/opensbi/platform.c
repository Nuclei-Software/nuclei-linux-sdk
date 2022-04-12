/*
 * SPDX-License-Identifier: BSD-2-Clause
 *
 * Copyright (c) Nuclei Corporation or its affiliates.
 *
 * Authors:
 *   lujun <lujun@nucleisys.com>
 *   hqfang <hqfang@nucleisys.com>
 */

#include <libfdt.h>
#include <sbi/riscv_asm.h>
#include <sbi/riscv_io.h>
#include <sbi/riscv_encoding.h>
#include <sbi/sbi_console.h>
#include <sbi/sbi_const.h>
#include <sbi/sbi_platform.h>
#include <sbi_utils/fdt/fdt_fixup.h>
#include <sbi_utils/fdt/fdt_domain.h>
#include <sbi_utils/fdt/fdt_helper.h>
#include <sbi_utils/irqchip/plic.h>
#include <sbi_utils/serial/nuclei-uart.h>
#include <sbi_utils/sys/clint.h>
#include <sbi_utils/irqchip/fdt_irqchip.h>
#include <sbi_utils/serial/fdt_serial.h>
#include <sbi_utils/timer/fdt_timer.h>
#include <sbi_utils/ipi/fdt_ipi.h>
#include <sbi_utils/reset/fdt_reset.h>

#include "demosoc.h"

/* clang-format off */
#define NUCLEI_HART_COUNT                   8

#define DEMOSOC_PERIPH_BASE                 (0x10000000UL)                      /*!< (Peripheral) Base Address */
#define DEMOSOC_GPIO_BASE                   (DEMOSOC_PERIPH_BASE + 0x12000)     /*!< (GPIO) Base Address */
#define GPIO                                ((GPIO_TypeDef *) DEMOSOC_GPIO_BASE)

#define NUCLEI_GPIO_IOF_UART0_MASK          0x00030000
#define NUCLEI_GPIO_IOF_UART1_MASK          0x03000000
#define NUCLEI_GPIO_IOF_QSPI2_MASK          0xFC000000

#define NUCLEI_GPIO_INPUT_EN_UART0_MASK     0x00010000
#define NUCLEI_GPIO_INPUT_EN_UART1_MASK     0x01000000
#define NUCLEI_GPIO_INPUT_EN_QSPI2_MASK     0x10000000

#define NUCLEI_GPIO_OUTPUT_EN_UART0_MASK    0x00020000
#define NUCLEI_GPIO_OUTPUT_EN_UART1_MASK    0x02000000
#define NUCLEI_GPIO_OUTPUT_EN_QSPI2_MASK    0xEC000000

#define NUCLEI_GPIO_IOF_MASK                (NUCLEI_GPIO_IOF_UART0_MASK | \
                            NUCLEI_GPIO_IOF_UART1_MASK | NUCLEI_GPIO_IOF_QSPI2_MASK)

#define NUCLEI_GPIO_INPUT_EN_MASK           (NUCLEI_GPIO_INPUT_EN_UART0_MASK | \
                            NUCLEI_GPIO_INPUT_EN_UART1_MASK | NUCLEI_GPIO_INPUT_EN_QSPI2_MASK)

#define NUCLEI_GPIO_OUTPUT_EN_MASK    (NUCLEI_GPIO_OUTPUT_EN_UART0_MASK | \
                            NUCLEI_GPIO_OUTPUT_EN_UART1_MASK | NUCLEI_GPIO_OUTPUT_EN_QSPI2_MASK)

static int nuclei_early_init(bool cold_boot)
{
    if (cold_boot) {
        gpio_iof_config(GPIO, NUCLEI_GPIO_IOF_MASK, IOF_SEL_0);
        gpio_enable_output(GPIO, NUCLEI_GPIO_OUTPUT_EN_MASK);
        gpio_enable_input(GPIO, NUCLEI_GPIO_INPUT_EN_MASK);
    }
    return 0;
}

static void nuclei_modify_dt(void *fdt)
{
    fdt_cpu_fixup(fdt);
    fdt_fixups(fdt);
    fdt_domain_fixup(fdt);
}

static int nuclei_final_init(bool cold_boot)
{
    void *fdt;

    if (!cold_boot)
        return 0;

    fdt = sbi_scratch_thishart_arg1_ptr();
    nuclei_modify_dt(fdt);

    // Check mcfg_info.tee to see whether tee present
    if (csr_read(0xfc2) & 0x1) {
        // Enable U-Mode to access all regions by setting spmpcfg0 and spmpaddr0
        csr_write(0x1a0, 0x1f);
        csr_write(0x1b0, 0xffffffff);
    }

    return 0;
}

static int nuclei_system_reset_check(u32 type, u32 reason)
{
    return 1;
}

static void nuclei_system_reset(u32 type, u32 reason)
{
    while(1);
}

static int nuclei_domains_init(void)
{
    return fdt_domains_populate(sbi_scratch_thishart_arg1_ptr());
}

const struct sbi_platform_operations platform_ops = {
    .early_init         = nuclei_early_init,
    .final_init         = nuclei_final_init,
    .domains_init       = nuclei_domains_init,
    .console_putc       = fdt_serial_putc,
    .console_getc       = fdt_serial_getc,
    .console_init       = fdt_serial_init,
    .irqchip_init       = fdt_irqchip_init,
    .irqchip_exit       = fdt_irqchip_exit,
    .ipi_send           = fdt_ipi_send,
    .ipi_clear          = fdt_ipi_clear,
    .ipi_init           = fdt_ipi_init,
    .ipi_exit           = fdt_ipi_exit,
    .timer_value        = fdt_timer_value,
    .timer_event_stop   = fdt_timer_event_stop,
    .timer_event_start  = fdt_timer_event_start,
    .timer_init         = fdt_timer_init,
    .timer_exit         = fdt_timer_exit,
    .system_reset_check = nuclei_system_reset_check,
    .system_reset       = nuclei_system_reset
};

static u32 nuclei_hart_index2id[NUCLEI_HART_COUNT] = {
    [0] = 0,
    [1] = 1,
    [2] = 2,
    [3] = 3,
    [4] = 4,
    [5] = 5,
    [6] = 6,
    [7] = 7,
};

const struct sbi_platform platform = {
    .opensbi_version    = OPENSBI_VERSION,
    .platform_version   = SBI_PLATFORM_VERSION(0x0U, 0x01U),
    .name               = "Nuclei Demo SoC",
    .features           = SBI_PLATFORM_DEFAULT_FEATURES,
    .hart_count         = NUCLEI_HART_COUNT,
    .hart_index2id      = nuclei_hart_index2id,
    .hart_stack_size    = SBI_PLATFORM_DEFAULT_HART_STACK_SIZE,
    .platform_ops_addr  = (unsigned long)&platform_ops
};

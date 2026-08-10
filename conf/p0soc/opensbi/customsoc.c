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
#include <sbi/riscv_io.h>

extern unsigned long clint_offset_quirk;
static const struct fdt_match nuclei_customsoc_match[] = {
	{ .compatible = "nuclei,customsoc" },
	{ .compatible = "nuclei,eval-soc" },
	{ .compatible = "nuclei,p0soc" },
	{ },
};

#define	NUCLEI_SYS_CACHE_BASE			0xf9c490000ULL
#define	NUCLEI_XEC1_MISC_BASE			0xf9cdb0000ULL
#define	NUCLEI_IOMUX_BASE				0xf9ca00000ULL
#define	NUCLEI_SYS_MISC_BASE			0xf9c880000ULL
#define	NUCLEI_AOND_MISC_BASE			0xf9c100000ULL

static int nuclei_customsoc_final_init(bool cold_boot,
				   const struct fdt_match *match)
{
	if (cold_boot) { // Add cold boot initial steps
		u32 val;

		/* disable lm_way */
		writel(0, (void*)(NUCLEI_SYS_CACHE_BASE + 0xd8));
		/* config NC area 0x7E000000, 0x200000 */
		writel(0xffe00000, (void*)(NUCLEI_SYS_CACHE_BASE + 0x608));
		writel(0x7E000005, (void*)(NUCLEI_SYS_CACHE_BASE + 0x408));
		/* enable syscache as last cache */
		val = readl((void*)(NUCLEI_SYS_CACHE_BASE + 0x10));
		val |= 0x1;
		writel(val, (void*)(NUCLEI_SYS_CACHE_BASE + 0x10));

		/* enable cluster2 req sysrst */
		val = readl((void *)(0xf9c100000 + 0xc80));
		val |= 1 << 13;
		writel(val, (void *)(0xf9c100000 + 0xc80));
		/* init xec0 clk and reset xec0 ip */

		/* config xec_gen20_clk_i to 500M/(19+1) = 25MHZ */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x2f8));
		val &= ~0xff;
		val |= 19;
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x2f8));
		/* config rmii clk_ref_i to 500/(9+1)=50MHZ */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x300));
		val &= ~0xff;
		val |= 0x9;
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x300));
		/* enable xec0 clk */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x48));
		val |= 1 << 2;
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x48));
		/* reset xec0 ip */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x28));
		val &= ~(1 << 2);
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x28));
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x28));
		val |= (1 << 2);
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x28));

		/* init xec1 clk and reset xec1 ip */
		/* config xec_gen21_clk_i to 500M/(3+1) = 125MHZ */
		val = readl((void *)(NUCLEI_XEC1_MISC_BASE + 0x2fc));
		val &= ~0xff;
		val |= 3;
		writel(val, (void *)(NUCLEI_XEC1_MISC_BASE + 0x2fc));
		/* config rmii clk_ref_i to 500/(9+1)=50MHZ */
		val = readl((void *)(NUCLEI_XEC1_MISC_BASE + 0x300));
		val &= ~0xff;
		val |= 0x9;
		writel(val, (void *)(NUCLEI_XEC1_MISC_BASE + 0x300));
		/* enable xec1 clk */
		val = readl((void *)(NUCLEI_XEC1_MISC_BASE + 0x48));
		val |= 1 << 3;
		writel(val, (void *)(NUCLEI_XEC1_MISC_BASE + 0x48));
		/* reset xec1 ip */
		val = readl((void *)(NUCLEI_XEC1_MISC_BASE + 0x28));
		val &= ~(1 << 3);
		writel(val, (void *)(NUCLEI_XEC1_MISC_BASE + 0x28));
		val = readl((void *)(NUCLEI_XEC1_MISC_BASE + 0x28));
		val |= (1 << 3);
		writel(val, (void *)(NUCLEI_XEC1_MISC_BASE + 0x28));

		/* enable i2c0 clk */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x40));
		val |= 1 << 22;
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x40));

		/* reset i2c0 */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x20));
		val &= ~(1 << 22);
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x20));
		val |= (1 << 22);
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x20));

		/* i2c0 bus clk 200/4=50M */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x210));
		val &= ~0xff;
		val |= 3;
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x210));
		/* i2c kernel clk 200/25=8M */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x214));
		val &= ~0xff;
		val |= 24;
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x214));

		/* enable acc_udma clk */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x4c));
		val |= (1 << 0) | (1 << 2);
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x4c));
		/* reset acc_udma */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x2c));
		val &= ~((1 << 0) | (1 << 2));
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x2c));
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x2c));
		val |= (1 << 0) | (1 << 2);
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x2c));

		/* enable spi0 clk */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x40));
		val |= (1 << 28);
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x40));
		/* reset spi0 */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x20));
		val &= ~(1 << 28);
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x20));
		val |= (1 << 28);
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x20));
		/* spi0 bus clk 200/2=100M */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x238));
		val &= ~0xff;
		val |= 1;
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x238));
		/* spi0 kernel clk 200/2=100M */
		val = readl((void *)(NUCLEI_SYS_MISC_BASE + 0x23C));
		val &= ~0xff;
		val |= 1;
		writel(val, (void *)(NUCLEI_SYS_MISC_BASE + 0x23C));
	}

	// Check mcfg_info.tee to see whether tee present
	if (csr_read(0xfc2) & 0x1) {
		// Enable U-Mode to access all regions by setting spmpcfg0 and spmpaddr0
		csr_write(0x1a0, 0x1f);
		csr_write(0x1b0, 0xffffffff);
	}

	#define mattri1_base 0x7f5
	#define mattri1_mask 0x7f6
	/* config base:0x7E000000, size:2MB to noncachable */
	csr_write(mattri1_mask, 0xffe00000);
	csr_write(mattri1_base, 0x7E000005);

	return 0;
}

static int nuclei_customsoc_early_init(bool cold_boot,
				   const struct fdt_match *match)
{
	/*
	* The NUCLEI CLINT address is not aligned to 0x10000 boundary, which would require
	* additional PMP entries to configure permissions for the CLINT region.
	* the clint_offset_quirk var to fixup this issue.
	*/
	clint_offset_quirk = 0x1000;

	/* switch mtime clk to aond_sys_clk 1MHZ, 20MHZ/(19+1)=1MHZ */

	writel(1, (void *)(NUCLEI_AOND_MISC_BASE + 0x104));
	writel(19, (void *)(NUCLEI_AOND_MISC_BASE + 0x108));
	writel(2, (void *)(NUCLEI_AOND_MISC_BASE + 0x110));

	return 0;
}

const struct platform_override nuclei_customsoc = {
	.match_table = nuclei_customsoc_match,
	.early_init = nuclei_customsoc_early_init,
	.final_init = nuclei_customsoc_final_init,
};

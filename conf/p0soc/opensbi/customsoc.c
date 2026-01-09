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

#define	NUCLEI_XEC1_MISC_BASE			0xf9cdb0000ULL
#define	NUCLEI_IOMUX_BASE				0xf9ca00000ULL
#define	NUCLEI_SYS_MISC_BASE			0xf9c880000ULL

#define	LS_SRC_SEL_OFS(grp_id)			(0x0000+grp_id*0x20000)
#define	HS_CHNL_SEL_OFS(grp_id)			(0x2000+grp_id*0x20000)
#define	LS_SRC0_IVAL_SEL_OFS(grp_id)	(0x4000+grp_id*0x20000)

#define	PHY_CNTRL_OFS(grp_id)			(0x6000+grp_id*0x20000)
#define	CNTRL_SEL_OFS(grp_id)			(0x08000+grp_id*0x20000)

#define	DO_SEL(regval)					((BIT(5)|BIT(6)) & ((u32)(regval) << 5))
#define	DO_SEL_PAD_PHYSICAL				DO_SEL(0)              /*!<  DO_SEL_PHY   */
#define	DO_SEL_HS						DO_SEL(1)              /*!<  DO_SEL_HS*/
#define	DO_SEL_OE						DO_SEL(2)              /*!<  DO_SEL_OE */

#define	IE_SEL							BIT(0)

#define	OE_SEL(regval)					((BIT(3)|BIT(4)) & ((u32)(regval) << 3))
#define	OE_SEL_PAD_PHYSICAL				OE_SEL(0)              /*!<  PAD_PHYSICAL */
#define	OE_SEL_HS_CHANNEL				OE_SEL(1)              /*!<  OE_HS_CHANNEL */
#define	OE_SEL_OVAL_HS_CHANNEL			OE_SEL(2)              /*!<  OVAL_HS_CHANNEL */

#define	PAD_NUM							169

struct ls_grp_iof_t{
	u32 grp_iof_start_id;
	u32 grp_iof_end_id;
};

struct ls_grp_iof_t ls_grp_iof[]={
	{.grp_iof_start_id = 0, .grp_iof_end_id=47},
	{.grp_iof_start_id = 1, .grp_iof_end_id=106},
	{.grp_iof_start_id = 2, .grp_iof_end_id=162},
	{.grp_iof_start_id = 163, .grp_iof_end_id=217},
	{.grp_iof_start_id = 218, .grp_iof_end_id=267},
	{.grp_iof_start_id = 268, .grp_iof_end_id=316},
	{.grp_iof_start_id = 317, .grp_iof_end_id=360},
	{.grp_iof_start_id = 361, .grp_iof_end_id=403},
};

u32 pad_to_group[PAD_NUM] = {
	[0 ... 21] = 0,    // pad 0-21  group 0
	[22 ... 42] = 1,   // pad 22-42  group 1
	[43 ... 63] = 2,   // pad 43-63  group 2
	[64 ... 84] = 3,   // pad 64-84  group 3
	[85 ... 105] = 4,  // pad 85-105  group 4
	[106 ... 126] = 5, // pad 106-126  group 5
	[127 ... 147] = 6, // pad 127-147  group 6
	[148 ... 168] = 7  // pad 148-168  group 7
};

static u32 set_pad_ls_ival_tie0(unsigned long iomux_base,u32 pad_id)
{
	u32 grp_id;

	grp_id = pad_to_group[pad_id];
	for(u32 i = ls_grp_iof[grp_id].grp_iof_start_id ;i<ls_grp_iof[grp_id].grp_iof_end_id+1; i++)
	{
		if(readl((void *)(iomux_base + LS_SRC0_IVAL_SEL_OFS(grp_id) + 0x4 * i))== pad_id)
		{
			writel(PAD_NUM + 1, (void *)(iomux_base + LS_SRC0_IVAL_SEL_OFS(grp_id) + 0x4 * i));
		}
	}

	return 0;
}

static void config_hs_io_ival(unsigned long iomux_base, u32 per_iof_id,u32 pad_id, u32 hs_grp)
{
	unsigned long val;

	set_pad_ls_ival_tie0(iomux_base, pad_id);
	writel(hs_grp, (void *)(iomux_base + HS_CHNL_SEL_OFS(pad_to_group[pad_id]) + 0x4 * per_iof_id));

	val = readl((void *)(iomux_base + CNTRL_SEL_OFS(pad_to_group[pad_id]) + 0x4 * per_iof_id));
	val |= DO_SEL_HS | IE_SEL;
	writel(val, (void *)(iomux_base + CNTRL_SEL_OFS(pad_to_group[pad_id]) + 0x4 * per_iof_id));
}

static void config_hs_io_oval(unsigned long iomux_base, u32 per_iof_id,u32 pad_id, u32 hs_grp)
{
	unsigned long val;

	writel(hs_grp, (void *)(iomux_base + HS_CHNL_SEL_OFS(pad_to_group[pad_id]) + 0x4 * per_iof_id));
	val = readl((void *)(iomux_base + CNTRL_SEL_OFS(pad_to_group[pad_id]) + 0x4 * per_iof_id));
	val |= DO_SEL_HS | OE_SEL_HS_CHANNEL;
	writel(val, (void *)(iomux_base + CNTRL_SEL_OFS(pad_to_group[pad_id]) + 0x4 * per_iof_id));
}

void config_iomux_xec0(void)
{
	/* mdio ival */
	config_hs_io_ival(NUCLEI_IOMUX_BASE, 16, 16, 1);
	/* mdc ival */
	config_hs_io_ival(NUCLEI_IOMUX_BASE, 17, 17, 1);
	/* rxc */
	config_hs_io_ival(NUCLEI_IOMUX_BASE, 26, 26, 1);
	/* rxd3 */
	config_hs_io_ival(NUCLEI_IOMUX_BASE, 27, 27, 1);
	/* rxd2 */
	config_hs_io_ival(NUCLEI_IOMUX_BASE, 28, 28, 1);
	/* rxd1 */
	config_hs_io_ival(NUCLEI_IOMUX_BASE, 29, 29, 1);
	/* rxd0 */
	config_hs_io_ival(NUCLEI_IOMUX_BASE, 30, 30, 1);
	/* rxdv */
	config_hs_io_ival(NUCLEI_IOMUX_BASE, 31, 31, 1);
	/* rver */
	config_hs_io_ival(NUCLEI_IOMUX_BASE, 32, 32, 1);

	/* mdio oval */
	config_hs_io_oval(NUCLEI_IOMUX_BASE, 16, 16, 1);
	/* mdc oval */
	config_hs_io_oval(NUCLEI_IOMUX_BASE, 17, 17, 1);
	/* txen oval */
	config_hs_io_oval(NUCLEI_IOMUX_BASE, 18, 18, 1);
	/* txd3 oval */
	config_hs_io_oval(NUCLEI_IOMUX_BASE, 21, 21, 1);
	/* txd2 oval */
	config_hs_io_oval(NUCLEI_IOMUX_BASE, 22, 22, 1);
	/* txd1 oval */
	config_hs_io_oval(NUCLEI_IOMUX_BASE, 23, 23, 1);
	/* txd0 oval */
	config_hs_io_oval(NUCLEI_IOMUX_BASE, 24, 24, 1);
	/* txc oval */
	config_hs_io_oval(NUCLEI_IOMUX_BASE, 25, 25, 1);
	/* col oval */
	config_hs_io_oval(NUCLEI_IOMUX_BASE, 33, 33, 1);
	/* crs oval */
	config_hs_io_oval(NUCLEI_IOMUX_BASE, 34, 34, 1);
	/* txer oval */
	config_hs_io_oval(NUCLEI_IOMUX_BASE, 35, 35, 1);
}

static int nuclei_customsoc_final_init(bool cold_boot,
				   const struct fdt_match *match)
{
	if (cold_boot) { // Add cold boot initial steps
		u32 val;
		/* enable cluster2 req sysrst */
		val = readl((void *)(0xf9c100000 + 0xc80));
		val |= 1 << 13;
		writel(val, (void *)(0xf9c100000 + 0xc80));
		/* init xec0 clk and reset xec0 ip */

		/* config xec0 iomux */
		config_iomux_xec0();
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
	}

	// Check mcfg_info.tee to see whether tee present
	if (csr_read(0xfc2) & 0x1) {
		// Enable U-Mode to access all regions by setting spmpcfg0 and spmpaddr0
		csr_write(0x1a0, 0x1f);
		csr_write(0x1b0, 0xffffffff);
	}

	/*
	 * If arch is rv32 or rv64 without svpbmt feature, you can use mattri to set ddr base:0xfd000000,size:0x10000 as non-cachable region.
	 * xec dts node should contain desc_mem region from base:0xfd000000,size:0x10000; which is reserved region used to store xec descriptors.
	 * if rv64 with svpbmt feature, xec dts node must not contain desc_mem property.
	 */
#if __riscv_xlen == 32
	#define mattri1_base 0x7f5
	#define mattri1_mask 0x7f6

	csr_write(mattri1_mask, 0xffff0000);
	csr_write(mattri1_base, 0xfd000005);
#endif

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

	return 0;
}

const struct platform_override nuclei_customsoc = {
	.match_table = nuclei_customsoc_match,
	.early_init = nuclei_customsoc_early_init,
	.final_init = nuclei_customsoc_final_init,
};

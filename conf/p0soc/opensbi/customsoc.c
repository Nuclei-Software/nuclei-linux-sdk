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

#define	I2C0_SCL_IOF_IVAL				60
#define	I2C0_SCL_IOF_OVAL				60
#define	I2C0_SDA_IOF_IVAL				61
#define I2C0_SDA_IOF_OVAL				61
#define	I2C0_SCL_PAD_SEL				36
#define	I2C0_SDA_PAD_SEL				37
#define	LS_SRC_SEL_OFS(grp_id)			(0x0000+grp_id*0x20000)
#define	HS_CHNL_SEL_OFS(grp_id)			(0x2000+grp_id*0x20000)
#define	LS_SRC0_IVAL_SEL_OFS(grp_id)	(0x4000+grp_id*0x20000)

#define	PHY_CNTRL_OFS(grp_id)			(0x6000+grp_id*0x20000)
#define	CNTRL_SEL_OFS(grp_id)			(0x08000+grp_id*0x20000)

#define	DO_SEL(regval)					((BIT(5)|BIT(6)) & ((u32)(regval) << 5))
#define	DO_SEL_PAD_PHYSICAL				DO_SEL(0)              /*!<  DO_SEL_PHY   */
#define	DO_SEL_HS						DO_SEL(1)              /*!<  DO_SEL_HS*/
#define	DO_SEL_OE						DO_SEL(2)              /*!<  DO_SEL_OE */

#define	PU								BIT(18)
#define	IE_SEL							BIT(0)

#define	OE_SEL(regval)					((BIT(3)|BIT(4)) & ((u32)(regval) << 3))
#define	OE_SEL_PAD_PHYSICAL				OE_SEL(0)              /*!<  PAD_PHYSICAL */
#define	OE_SEL_HS_CHANNEL				OE_SEL(1)              /*!<  OE_HS_CHANNEL */
#define	OE_SEL_OVAL_HS_CHANNEL			OE_SEL(2)              /*!<  OVAL_HS_CHANNEL */

#define	PAD_NUM							169

struct pad_group{
	uint32_t pad_id;
	uint32_t group_id;
};

struct ls_grp_iof_t{
	u32 grp_iof_start_id;
	u32 grp_iof_end_id;
};

static struct pad_group pad_goup_info[]=
{
	{ .pad_id = 0,.group_id=0},
	{ .pad_id = 1,.group_id=0},
	{ .pad_id = 2,.group_id=0},
	{ .pad_id = 3,.group_id=0},
	{ .pad_id = 4,.group_id=0},
	{ .pad_id = 5,.group_id=0},
	{ .pad_id = 6,.group_id=0},
	{ .pad_id = 7,.group_id=0},
	{ .pad_id = 8,.group_id=0},
	{ .pad_id = 9,.group_id=0},
	{ .pad_id = 10,.group_id=0},
	{ .pad_id = 11,.group_id=0},
	{ .pad_id = 12,.group_id=0},
	{ .pad_id = 13,.group_id=0},
	{ .pad_id = 14,.group_id=0},
	{ .pad_id = 15,.group_id=0},
	{ .pad_id = 16,.group_id=0},
	{ .pad_id = 17,.group_id=0},
	{ .pad_id = 18,.group_id=0},
	{ .pad_id = 19,.group_id=0},
	{ .pad_id = 20,.group_id=0},
	{ .pad_id = 21,.group_id=0},
	{ .pad_id = 22,.group_id=1},
	{ .pad_id = 23,.group_id=1},
	{ .pad_id = 24,.group_id=1},
	{ .pad_id = 25,.group_id=1},
	{ .pad_id = 26,.group_id=1},
	{ .pad_id = 27,.group_id=1},
	{ .pad_id = 28,.group_id=1},
	{ .pad_id = 29,.group_id=1},
	{ .pad_id = 30,.group_id=1},
	{ .pad_id = 31,.group_id=1},
	{ .pad_id = 32,.group_id=1},
	{ .pad_id = 33,.group_id=1},
	{ .pad_id = 34,.group_id=1},
	{ .pad_id = 35,.group_id=1},
	{ .pad_id = 36,.group_id=1},
	{ .pad_id = 37,.group_id=1},
	{ .pad_id = 38,.group_id=1},
	{ .pad_id = 39,.group_id=1},
	{ .pad_id = 40,.group_id=1},
	{ .pad_id = 41,.group_id=1},
	{ .pad_id = 42,.group_id=1},
	{ .pad_id = 43,.group_id=2},
	{ .pad_id = 44,.group_id=2},
	{ .pad_id = 45,.group_id=2},
	{ .pad_id = 46,.group_id=2},
	{ .pad_id = 47,.group_id=2},
	{ .pad_id = 48,.group_id=2},
	{ .pad_id = 49,.group_id=2},
	{ .pad_id = 50,.group_id=2},
	{ .pad_id = 51,.group_id=2},
	{ .pad_id = 52,.group_id=2},
	{ .pad_id = 53,.group_id=2},
	{ .pad_id = 54,.group_id=2},
	{ .pad_id = 55,.group_id=2},
	{ .pad_id = 56,.group_id=2},
	{ .pad_id = 57,.group_id=2},
	{ .pad_id = 58,.group_id=2},
	{ .pad_id = 59,.group_id=2},
	{ .pad_id = 60,.group_id=2},
	{ .pad_id = 61,.group_id=2},
	{ .pad_id = 62,.group_id=2},
	{ .pad_id = 63,.group_id=2},
	{ .pad_id = 64,.group_id=3},
	{ .pad_id = 65,.group_id=3},
	{ .pad_id = 66,.group_id=3},
	{ .pad_id = 67,.group_id=3},
	{ .pad_id = 68,.group_id=3},
	{ .pad_id = 69,.group_id=3},
	{ .pad_id = 70,.group_id=3},
	{ .pad_id = 71,.group_id=3},
	{ .pad_id = 72,.group_id=3},
	{ .pad_id = 73,.group_id=3},
	{ .pad_id = 74,.group_id=3},
	{ .pad_id = 75,.group_id=3},
	{ .pad_id = 76,.group_id=3},
	{ .pad_id = 77,.group_id=3},
	{ .pad_id = 78,.group_id=3},
	{ .pad_id = 79,.group_id=3},
	{ .pad_id = 80,.group_id=3},
	{ .pad_id = 81,.group_id=3},
	{ .pad_id = 82,.group_id=3},
	{ .pad_id = 83,.group_id=3},
	{ .pad_id = 84,.group_id=3},
	{ .pad_id = 85,.group_id=4},
	{ .pad_id = 86,.group_id=4},
	{ .pad_id = 87,.group_id=4},
	{ .pad_id = 88,.group_id=4},
	{ .pad_id = 89,.group_id=4},
	{ .pad_id = 90,.group_id=4},
	{ .pad_id = 91,.group_id=4},
	{ .pad_id = 92,.group_id=4},
	{ .pad_id = 93,.group_id=4},
	{ .pad_id = 94,.group_id=4},
	{ .pad_id = 95,.group_id=4},
	{ .pad_id = 96,.group_id=4},
	{ .pad_id = 97,.group_id=4},
	{ .pad_id = 98,.group_id=4},
	{ .pad_id = 99,.group_id=4},
	{ .pad_id = 100,.group_id=4},
	{ .pad_id = 101,.group_id=4},
	{ .pad_id = 102,.group_id=4},
	{ .pad_id = 103,.group_id=4},
	{ .pad_id = 104,.group_id=4},
	{ .pad_id = 105,.group_id=4},
	{ .pad_id = 106,.group_id=5},
	{ .pad_id = 107,.group_id=5},
	{ .pad_id = 108,.group_id=5},
	{ .pad_id = 109,.group_id=5},
	{ .pad_id = 110,.group_id=5},
	{ .pad_id = 111,.group_id=5},
	{ .pad_id = 112,.group_id=5},
	{ .pad_id = 113,.group_id=5},
	{ .pad_id = 114,.group_id=5},
	{ .pad_id = 115,.group_id=5},
	{ .pad_id = 116,.group_id=5},
	{ .pad_id = 117,.group_id=5},
	{ .pad_id = 118,.group_id=5},
	{ .pad_id = 119,.group_id=5},
	{ .pad_id = 120,.group_id=5},
	{ .pad_id = 121,.group_id=5},
	{ .pad_id = 122,.group_id=5},
	{ .pad_id = 123,.group_id=5},
	{ .pad_id = 124,.group_id=5},
	{ .pad_id = 125,.group_id=5},
	{ .pad_id = 126,.group_id=5},
	{ .pad_id = 127,.group_id=6},
	{ .pad_id = 128,.group_id=6},
	{ .pad_id = 129,.group_id=6},
	{ .pad_id = 130,.group_id=6},
	{ .pad_id = 131,.group_id=6},
	{ .pad_id = 132,.group_id=6},
	{ .pad_id = 133,.group_id=6},
	{ .pad_id = 134,.group_id=6},
	{ .pad_id = 135,.group_id=6},
	{ .pad_id = 136,.group_id=6},
	{ .pad_id = 137,.group_id=6},
	{ .pad_id = 138,.group_id=6},
	{ .pad_id = 139,.group_id=6},
	{ .pad_id = 140,.group_id=6},
	{ .pad_id = 141,.group_id=6},
	{ .pad_id = 142,.group_id=6},
	{ .pad_id = 143,.group_id=6},
	{ .pad_id = 144,.group_id=6},
	{ .pad_id = 145,.group_id=6},
	{ .pad_id = 146,.group_id=6},
	{ .pad_id = 147,.group_id=6},
	{ .pad_id = 148,.group_id=7},
	{ .pad_id = 149,.group_id=7},
	{ .pad_id = 150,.group_id=7},
	{ .pad_id = 151,.group_id=7},
	{ .pad_id = 152,.group_id=7},
	{ .pad_id = 153,.group_id=7},
	{ .pad_id = 154,.group_id=7},
	{ .pad_id = 155,.group_id=7},
	{ .pad_id = 156,.group_id=7},
	{ .pad_id = 157,.group_id=7},
	{ .pad_id = 158,.group_id=7},
	{ .pad_id = 159,.group_id=7},
	{ .pad_id = 160,.group_id=7},
	{ .pad_id = 161,.group_id=7},
	{ .pad_id = 162,.group_id=7},
	{ .pad_id = 163,.group_id=7},
	{ .pad_id = 164,.group_id=7},
	{ .pad_id = 165,.group_id=7},
	{ .pad_id = 166,.group_id=7},
	{ .pad_id = 167,.group_id=7},
	{ .pad_id = 168,.group_id=7},
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

static u32 set_pad_ls_ival_tie0(unsigned long iomux_base,u32 pad_id)
{
	u32 grp_id;

	grp_id = pad_goup_info[pad_id].group_id;
	for(u32 i = ls_grp_iof[grp_id].grp_iof_start_id ;i<ls_grp_iof[grp_id].grp_iof_end_id+1; i++)
	{
		if(readl((void *)(iomux_base + LS_SRC0_IVAL_SEL_OFS(grp_id) + 0x4 * i))== pad_id)
		{
			writel(PAD_NUM + 1, (void *)(iomux_base + LS_SRC0_IVAL_SEL_OFS(grp_id) + 0x4 * i));
		}
	}

	return 0;
}

static uint32_t get_pad_group(uint32_t pad_id)
{
	uint32_t index=0xFFFFFFFF;

	if(pad_goup_info[pad_id].pad_id != pad_id)
	{
		for(int i=0; i<pad_id; i++)
		{
			if(pad_goup_info[i].pad_id == pad_id)
			{
				index=i;
				break;
			}
		}
	}else{
		index=pad_id;
	}
	return index ;
}

void iomux_ls_iof_ival_cfg(unsigned long iomux_base, uint32_t per_iof_id,uint32_t pad_id, uint8_t hs_ls)
{
	uint32_t pad_index;
	long unsigned val;

	pad_index=get_pad_group(pad_id);
	switch(hs_ls)
	{
		case 0:
			writel(per_iof_id, (void *)(iomux_base + LS_SRC_SEL_OFS(pad_goup_info[pad_id].group_id) + 0x4 * pad_id));
			writel(pad_id, (void *)(iomux_base + LS_SRC0_IVAL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * per_iof_id));
			val = readl((void*)(iomux_base + CNTRL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * pad_id));
			val = val | 0x1;
			writel(val, (void*)(iomux_base + CNTRL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * pad_id));
			val = readl((void*)(iomux_base + CNTRL_SEL_OFS(pad_goup_info[pad_id].group_id) + 0x4 * pad_id));
			val &= ~(BIT(3));
			writel(val, (void*)(iomux_base + CNTRL_SEL_OFS(pad_goup_info[pad_id].group_id) + 0x4 * pad_id)) ;
			break;
		case 1:
		case 2:
		case 3:
			set_pad_ls_ival_tie0(iomux_base, pad_id);
			writel(hs_ls, (void *)(iomux_base + HS_CHNL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * per_iof_id));
			val = readl((void*)(iomux_base + CNTRL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * per_iof_id));
			val |= DO_SEL_HS | IE_SEL;
			writel(val, (void*)(iomux_base + CNTRL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * per_iof_id));
			break;
		default:
			break;
	}
}

void iomux_ls_iof_oval_cfg(unsigned long iomux_base, uint32_t per_iof_id,uint32_t pad_id, uint8_t hs_ls)
{
	uint32_t pad_index;
	long unsigned val;

	pad_index=get_pad_group(pad_id);
	switch(hs_ls)
	{
		case 0:
			writel(per_iof_id, (void*)(iomux_base + LS_SRC_SEL_OFS(pad_goup_info[pad_index].group_id)    + 0x4 * pad_id));
			writel(hs_ls, (void*)(iomux_base + HS_CHNL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * pad_id));
			val = readl((void*)(iomux_base + CNTRL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * pad_id));
			val |= DO_SEL_HS | OE_SEL_HS_CHANNEL;
			writel(val, (void*)(iomux_base + CNTRL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * pad_id));
			break;
		case 1:
		case 2:
		case 3:
			writel(hs_ls, (void*)(iomux_base + HS_CHNL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * per_iof_id));
			val = readl((void*)(iomux_base + CNTRL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * per_iof_id));
			val |= DO_SEL_HS | OE_SEL_HS_CHANNEL;
			writel(val, (void*)(iomux_base + CNTRL_SEL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * per_iof_id));
			break;

		default:
			break;
	}
}

void iomux_ls_iof_pullup_cfg(unsigned long iomux_base, uint32_t pad_id, uint8_t hs_ls)
{
	uint32_t pad_index;
	long unsigned val;

	pad_index=get_pad_group(pad_id);
	val = readl((void *)(iomux_base + PHY_CNTRL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * pad_id));
	val |= PU;
	writel(val, (void *)(iomux_base + PHY_CNTRL_OFS(pad_goup_info[pad_index].group_id) + 0x4 * pad_id));
}

void config_iomux_xec0(void)
{
	/* mdio ival */
	iomux_ls_iof_ival_cfg(NUCLEI_IOMUX_BASE, 16, 16, 1);
	/* mdc ival */
	iomux_ls_iof_ival_cfg(NUCLEI_IOMUX_BASE, 17, 17, 1);
	/* rxc */
	iomux_ls_iof_ival_cfg(NUCLEI_IOMUX_BASE, 26, 26, 1);
	/* rxd3 */
	iomux_ls_iof_ival_cfg(NUCLEI_IOMUX_BASE, 27, 27, 1);
	/* rxd2 */
	iomux_ls_iof_ival_cfg(NUCLEI_IOMUX_BASE, 28, 28, 1);
	/* rxd1 */
	iomux_ls_iof_ival_cfg(NUCLEI_IOMUX_BASE, 29, 29, 1);
	/* rxd0 */
	iomux_ls_iof_ival_cfg(NUCLEI_IOMUX_BASE, 30, 30, 1);
	/* rxdv */
	iomux_ls_iof_ival_cfg(NUCLEI_IOMUX_BASE, 31, 31, 1);
	/* rver */
	iomux_ls_iof_ival_cfg(NUCLEI_IOMUX_BASE, 32, 32, 1);

	/* mdio oval */
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, 16, 16, 1);
	/* mdc oval */
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, 17, 17, 1);
	/* txen oval */
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, 18, 18, 1);
	/* txd3 oval */
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, 21, 21, 1);
	/* txd2 oval */
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, 22, 22, 1);
	/* txd1 oval */
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, 23, 23, 1);
	/* txd0 oval */
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, 24, 24, 1);
	/* txc oval */
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, 25, 25, 1);
	/* col oval */
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, 33, 33, 1);
	/* crs oval */
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, 34, 34, 1);
	/* txer oval */
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, 35, 35, 1);
}

void config_iomux_i2c0(void)
{
	iomux_ls_iof_ival_cfg(NUCLEI_IOMUX_BASE, I2C0_SCL_IOF_IVAL, I2C0_SCL_PAD_SEL, 0);
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, I2C0_SCL_IOF_OVAL, I2C0_SCL_PAD_SEL, 0);
	iomux_ls_iof_ival_cfg(NUCLEI_IOMUX_BASE, I2C0_SDA_IOF_IVAL, I2C0_SDA_PAD_SEL, 0);
	iomux_ls_iof_oval_cfg(NUCLEI_IOMUX_BASE, I2C0_SDA_IOF_OVAL, I2C0_SDA_PAD_SEL, 0);

	iomux_ls_iof_pullup_cfg(NUCLEI_IOMUX_BASE, I2C0_SCL_PAD_SEL, 0);
	iomux_ls_iof_pullup_cfg(NUCLEI_IOMUX_BASE, I2C0_SDA_PAD_SEL, 0);
}

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

		/* init i2c iomux and enable i2c clk */
		config_iomux_i2c0();

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

	return 0;
}

const struct platform_override nuclei_customsoc = {
	.match_table = nuclei_customsoc_match,
	.early_init = nuclei_customsoc_early_init,
	.final_init = nuclei_customsoc_final_init,
};

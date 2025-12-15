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
#include <sbi/riscv_io.h>
#include <sbi/sbi_console.h>
#include <sbi_utils/fdt/fdt_helper.h>
#include <sbi_utils/fdt/fdt_fixup.h>

#define IOMUX_BASE 0xf8bc00000

#define REG32(p)                       (*(volatile uint32_t *) ((uintptr_t)(p)))
#define LS_SRC_SEL_OFS                 0x0000
#define HS_CHNL_SEL_OFS                0x4000
#define LS_SRC0_IVAL_SEL_OFS           0x8000

#define PHY_CNTRL_OFS                  0xC000
#define CNTRL_SEL_OFS                  0x10000

#define DO_SEL_HS                      32
#define OE_SEL_HS_CHANNEL              8
#define IE_SEL                         1

extern unsigned long clint_offset_quirk;
static const struct fdt_match nuclei_evalsoc_match[] = {
	{ .compatible = "nuclei,evalsoc" },
	{ .compatible = "nuclei,eval-soc" },
	{ },
};

void iomux_ls_iof_oval_cfg(unsigned long IO_MUX_BASE, uint32_t per_iof_num,uint32_t pad_num, uint8_t hs_ls,uint8_t  phy_cntr_sel,uint32_t phy_cntr)
{
   switch(hs_ls)
   {
       case 0:
            REG32((IO_MUX_BASE + LS_SRC_SEL_OFS    + 0x4 * pad_num))= per_iof_num ;
            REG32((IO_MUX_BASE + HS_CHNL_SEL_OFS + 0x4 * pad_num))= hs_ls ;
            REG32((IO_MUX_BASE + CNTRL_SEL_OFS + 0x4 * pad_num)) |=  DO_SEL_HS | OE_SEL_HS_CHANNEL ;
            break;
        case 1:
        case 2:
        case 3:
            REG32((IO_MUX_BASE + HS_CHNL_SEL_OFS + 0x4 * per_iof_num))= hs_ls ;
            REG32((IO_MUX_BASE + CNTRL_SEL_OFS + 0x4 * per_iof_num))|=  DO_SEL_HS | OE_SEL_HS_CHANNEL;
            break;

        default:
            break;
    }
}

void iomux_ls_iof_ival_cfg(unsigned long IO_MUX_BASE, uint32_t per_iof_num,uint32_t pad_num, uint8_t hs_ls ,uint8_t  phy_cntr_sel,uint32_t phy_cntr)
{
     switch(hs_ls)
    {
        case 0:
            REG32((IO_MUX_BASE + LS_SRC0_IVAL_SEL_OFS + 0x4 * per_iof_num))= pad_num ;
            REG32((IO_MUX_BASE + CNTRL_SEL_OFS + 0x4 * pad_num))|= 0x1 ;
            break;
        case 1:
        case 2:
        case 3:
            REG32((IO_MUX_BASE + HS_CHNL_SEL_OFS + 0x4 * per_iof_num))= hs_ls ;
            REG32((IO_MUX_BASE + CNTRL_SEL_OFS + 0x4 * per_iof_num))|=  DO_SEL_HS |  IE_SEL;
            break;
        default:
            break;
    }
}

static void xec_iomux_config(void)
{
    //XEC_GEN20_GMII_TXD_BIT0_IOF_OVAL
    iomux_ls_iof_oval_cfg(IOMUX_BASE,97, 97, 1, 0, 0);
    //XEC_GEN20_GMII_TXD_BIT1_IOF_OVAL
    iomux_ls_iof_oval_cfg(IOMUX_BASE,98, 98, 1, 0, 0);
    //XEC_GEN20_GMII_TXD_BIT2_IOF_OVAL
    iomux_ls_iof_oval_cfg(IOMUX_BASE,99, 99, 1, 0, 0);
    //XEC_GEN20_GMII_TXD_BIT3_IOF_OVAL
    iomux_ls_iof_oval_cfg(IOMUX_BASE,100, 100, 1, 0, 0);
    //XEC_GEN20_GMII_TXEN_IOF_OVAL
    iomux_ls_iof_oval_cfg(IOMUX_BASE,109, 109, 1, 0, 0);
    //XEC_GEN20_GMII_TXER_IOF_OVAL
    iomux_ls_iof_oval_cfg(IOMUX_BASE,110, 110, 1, 0, 0);
    //XEC_GEN20_XMII_TXC_IOF_OVAL
    iomux_ls_iof_ival_cfg(IOMUX_BASE,95, 95, 1, 0, 0);
    //XEC_GEN20_GMII_CRS_IOF_OVAL
    iomux_ls_iof_ival_cfg(IOMUX_BASE,105, 105, 1, 0, 0);
    //XEC_GEN20_GMII_COL_IOF_OVAL
    iomux_ls_iof_ival_cfg(IOMUX_BASE,106, 106, 1, 0, 0);
    //XEC_GEN20_GMII_RXC_IOF_IVAL
    iomux_ls_iof_ival_cfg(IOMUX_BASE,96, 96, 1, 0, 0);
    //XEC_GEN20_GMII_RXD_BIT0_IOF_IVAL
    iomux_ls_iof_ival_cfg(IOMUX_BASE,101, 101, 1, 0, 0);
    //XEC_GEN20_GMII_RXD_BIT1_IOF_IVAL
    iomux_ls_iof_ival_cfg(IOMUX_BASE,102, 102, 1, 0, 0);
    //XEC_GEN20_GMII_RXD_BIT2_IOF_IVAL
    iomux_ls_iof_ival_cfg(IOMUX_BASE,103, 103, 1, 0, 0);
    //XEC_GEN20_GMII_RXD_BIT3_IOF_IVAL
    iomux_ls_iof_ival_cfg(IOMUX_BASE,104, 104, 1, 0, 0);
    //XEC_GEN20_GMII_RXDV_IOF_IVAL
    iomux_ls_iof_ival_cfg(IOMUX_BASE,107, 107, 1, 0, 0);
    //XEC_GEN20_GMII_RXER_IOF_IVAL
    iomux_ls_iof_ival_cfg(IOMUX_BASE,108, 108, 1, 0, 0);
    //XEC_GEN20_GMII_RXC_IOF_IVAL
    iomux_ls_iof_ival_cfg(IOMUX_BASE,96, 96, 1, 0, 0);

    //GEN20 MDIO oval
    iomux_ls_iof_oval_cfg(IOMUX_BASE,19, 18, 0, 0, 0);
    //GEN20 MDC oval
    iomux_ls_iof_oval_cfg(IOMUX_BASE,20, 19, 0, 0, 0);
    //GEN20 MDIO ival
    iomux_ls_iof_ival_cfg(IOMUX_BASE,19, 18, 0, 0, 0);
}

static int nuclei_evalsoc_final_init(bool cold_boot,
				   const struct fdt_match *match)
{
	unsigned long smpcc_base = 0, smpcc_cfg;
	if (cold_boot) { // Add cold boot initial steps
		xec_iomux_config();
	}

	// Check mcfg_info.tee to see whether tee present
	if (csr_read(0xfc2) & 0x1) {
		// Enable U-Mode to access all regions by setting spmpcfg0 and spmpaddr0
		csr_write(0x1a0, 0x1f);
		csr_write(0x1b0, 0xffffffff);
	}

	// Check mcfg_info.smp to see whether smp present
	// if present, disable clm and enable l2 cache for boot hart
	if (csr_read(0xfc2) & (0x1 << 11) && cold_boot) {
		smpcc_base = csr_read(0x7f7) >> 10;
		smpcc_base = (smpcc_base << 10) + 0x40000;
		smpcc_cfg = readl((volatile void *)(smpcc_base + 0x4));
		sbi_printf("SMPCC BASE=0x%lx\n", smpcc_base);
		sbi_printf("SMPCC SMP_CFG=0x%lx\n", smpcc_cfg);
		if (smpcc_cfg & 0x1) { // L2 Cache Present
			sbi_printf("Disable CLM and enable L2 Cache\n");
			// Now Cluster Local Memory is not used any more since uboot spl stage is already done
			// We just disable this Cluster Local Memory feature and make it all L2 cache
			// set CLM_WAY_EN = 0x0
			writel(0, (volatile void *)(smpcc_base + 0xd8));
			// Enable L2
			// set CC_CTRL = 0x1
			writel(1, (volatile void *)(smpcc_base + 0x10));
		}
	}

	return 0;
}

static int nuclei_evalsoc_early_init(bool cold_boot,
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

const struct platform_override nuclei_evalsoc = {
	.match_table = nuclei_evalsoc_match,
	.early_init = nuclei_evalsoc_early_init,
	.final_init = nuclei_evalsoc_final_init,
};

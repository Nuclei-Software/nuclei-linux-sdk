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

static const struct fdt_match nuclei_evalsoc_match[] = {
	{ .compatible = "nuclei,evalsoc" },
	{ .compatible = "nuclei,eval-soc" },
	{ },
};

static int nuclei_evalsoc_final_init(bool cold_boot,
				   const struct fdt_match *match)
{
	unsigned long smpcc_base = 0, smpcc_cfg;
	if (cold_boot) { // Add cold boot initial steps
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

const struct platform_override nuclei_evalsoc = {
	.match_table = nuclei_evalsoc_match,
	.final_init = nuclei_evalsoc_final_init,
};

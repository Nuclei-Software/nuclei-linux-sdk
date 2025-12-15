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

extern unsigned long clint_offset_quirk;
static const struct fdt_match nuclei_evalsoc_match[] = {
	{ .compatible = "nuclei,evalsoc" },
	{ .compatible = "nuclei,eval-soc" },
	{ .compatible = "nuclei,placeholder" },
	{ },
};
extern void sm_init(bool cold_boot);
extern void opteed_cpu_on_handler(uint32_t linear_id);
static int nuclei_evalsoc_final_init(bool cold_boot,
				   const struct fdt_match *match)
{
	if (!cold_boot) { // Add cold boot initial steps
        /* warm boot to setup optee ctx for secondary cpu */
        unsigned int secondary_hartid;

        secondary_hartid = current_hartid();
        opteed_cpu_on_handler(secondary_hartid);

        return 0;
	}
	sm_init(cold_boot);
	// Check mcfg_info.tee to see whether tee present
	if (csr_read(0xfc2) & 0x1) {
		// Enable U-Mode to access all regions by setting spmpcfg0 and spmpaddr0
		csr_write(0x1a0, 0x1f);
		csr_write(0x1b0, 0xffffffff);
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

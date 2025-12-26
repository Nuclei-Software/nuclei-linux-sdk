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

static int nuclei_customsoc_final_init(bool cold_boot,
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

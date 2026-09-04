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
#include <sbi/sbi_bitops.h>
#include <sbi/sbi_console.h>
#include <sbi_utils/fdt/fdt_helper.h>
#include <sbi_utils/fdt/fdt_fixup.h>
#include <libfdt.h>

extern unsigned long clint_offset_quirk;
static uint32_t guest_index_bits = 0;
static uint32_t hw_smsi_align_bits = 0;

static const struct fdt_match nuclei_evalsoc_match[] = {
	{ .compatible = "nuclei,evalsoc" },
	{ .compatible = "nuclei,eval-soc" },
	{ .compatible = "nuclei,placeholder" },
	{ },
};

static int nuclei_evalsoc_get_geilen(void)
{
	int val;

	if (!misa_extension('H'))
		return 0;
	csr_write(CSR_HGEIE, -1UL);
	val = sbi_fls(csr_read(CSR_HGEIE));
	csr_write(CSR_HGEIE, 0);

	return val;
}

static void fdt_imsic_guest_index_fixup(void *fdt)
{
	int offset, len, i;
	const uint32_t *prop;
	int geilen;

	if (!fdt)
		return;

	offset = -1;
	for (i = 0; i < 2; i++) {
		offset = fdt_node_offset_by_compatible(fdt, offset, "riscv,imsics");
		if (offset < 0) {
			return;
		}

		prop = fdt_getprop(fdt, offset, "riscv,guest-index-bits", &len);
		if (prop) {
			break;
		}
	}
	if (!prop)
		return;
	guest_index_bits = fdt32_to_cpu(*prop);
	/*
	 * hw_smsi_align_bits = upper(log2(GEILEN+1)),
	 * if GEILEN=3 then hw_smsi_align_bits=2,
	 * if GEILEN=4 then hw_smsi_align_bits=3.
	 */
	geilen = nuclei_evalsoc_get_geilen();
	hw_smsi_align_bits = geilen ? (sbi_fls(geilen) + 1) : 0;
	if (guest_index_bits != hw_smsi_align_bits) {
		fdt_setprop_u32(fdt, offset, "riscv,guest-index-bits", hw_smsi_align_bits);
	}
}

static int nuclei_evalsoc_final_init(bool cold_boot,
				   const struct fdt_match *match)
{
	if (cold_boot) { // Add cold boot initial steps
		/*
		 * on nuclei_evalsoc_early_init stage, console has not been initialized,
		 * if need to update dts riscv,guest-index-bits prop, print related info here.
		 */
		if (guest_index_bits != hw_smsi_align_bits) {
			sbi_printf("Warning: dts prop riscv,guest-index-bits "
				"does not match with HW parameter GEILEN.\n");
			sbi_printf("Now update dts prop riscv,guest-index-bits "
				"from %d to %d to adapt HW.\n", guest_index_bits, hw_smsi_align_bits);
			sbi_printf("More details refer to https://github.com/"
					"Nuclei-Software/nuclei-linux-sdk/issues/36.\n");
		}
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

static int nuclei_evalsoc_early_init(bool cold_boot,
				   const struct fdt_match *match)
{
	/*
	* The NUCLEI CLINT address is not aligned to 0x10000 boundary, which would require
	* additional PMP entries to configure permissions for the CLINT region.
	* the clint_offset_quirk var to fixup this issue.
	*/
	clint_offset_quirk = 0x1000;

	if (cold_boot) {
		void *fdt;

		fdt = fdt_get_address();
		fdt_imsic_guest_index_fixup(fdt);
	}

	return 0;
}

const struct platform_override nuclei_evalsoc = {
	.match_table = nuclei_evalsoc_match,
	.early_init = nuclei_evalsoc_early_init,
	.final_init = nuclei_evalsoc_final_init,
};

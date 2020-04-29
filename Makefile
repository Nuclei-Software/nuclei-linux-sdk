ISA ?= rv64gc
ABI ?= lp64d
USE_HTIF ?= 0
EXTERNAL_TOOLCHAIN ?= 0

srcdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
srcdir := $(srcdir:/=)
confdir := $(srcdir)/conf
wrkdir := $(CURDIR)/work

buildroot_srcdir := $(srcdir)/buildroot
buildroot_initramfs_wrkdir := $(wrkdir)/buildroot_initramfs

# TODO: make RISCV be able to be set to alternate toolchain path
RISCV ?= $(buildroot_initramfs_wrkdir)/host
RVPATH := $(RISCV)/bin:$(PATH)
GITID := $(shell git describe --dirty --always)

platform_dts := $(confdir)/nuclei_ux600.dts
platform_dtb := $(wrkdir)/nuclei_ux600.dts

# The second option is the more standard version, however in
# the interest of reproducibility, use the buildroot version that
# we compile so as to minimize unepected surprises. 

ifeq (1,$(EXTERNAL_TOOLCHAIN))
target := riscv-nuclei-linux-gnu
CROSS_COMPILE := $(RISCV)/bin/$(target)-
buildroot_initramfs_config := $(confdir)/buildroot_ext_tool_initramfs_config
else
target := riscv64-nuclei-linux-gnu
CROSS_COMPILE := $(RISCV)/bin/$(target)-
buildroot_initramfs_config := $(confdir)/buildroot_initramfs_config
endif

buildroot_initramfs_tar := $(buildroot_initramfs_wrkdir)/images/rootfs.tar
buildroot_initramfs_sysroot_stamp := $(wrkdir)/.buildroot_initramfs_sysroot
buildroot_initramfs_sysroot := $(wrkdir)/buildroot_initramfs_sysroot

linux_srcdir := $(srcdir)/linux
linux_wrkdir := $(wrkdir)/linux
linux_defconfig := $(confdir)/linux_defconfig
linux_gen_initramfs=$(linux_srcdir)/usr/gen_initramfs.sh

vmlinux := $(linux_wrkdir)/vmlinux
vmlinux_stripped := $(linux_wrkdir)/vmlinux-stripped
vmlinux_bin := $(wrkdir)/vmlinux.bin

initramfs := $(wrkdir)/initramfs.cpio.gz

opensbi_srcdir := $(srcdir)/opensbi
opensbi_wrkdir := $(wrkdir)/opensbi
opensbi_payload := $(opensbi_wrkdir)/platform/nuclei/ux600/firmware/fw_payload.elf

# xlspike is prebuilt and installed to PATH
xlspike := xl_spike

target_gcc := $(CROSS_COMPILE)gcc

.PHONY: all
all: sim

$(buildroot_initramfs_wrkdir)/.config: $(buildroot_srcdir)
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp $(buildroot_initramfs_config) $@
	$(MAKE) -C $< RISCV=$(RISCV) O=$(buildroot_initramfs_wrkdir) olddefconfig 

# buildroot_initramfs provides gcc
$(buildroot_initramfs_tar): $(buildroot_srcdir) $(buildroot_initramfs_wrkdir)/.config $(buildroot_initramfs_config)
	$(MAKE) -C $< RISCV=$(RISCV) O=$(buildroot_initramfs_wrkdir)

.PHONY: buildroot_initramfs-menuconfig
buildroot_initramfs-menuconfig: $(buildroot_initramfs_wrkdir)/.config $(buildroot_srcdir)
	$(MAKE) -C $(dir $<) O=$(buildroot_initramfs_wrkdir) menuconfig
	$(MAKE) -C $(dir $<) O=$(buildroot_initramfs_wrkdir) savedefconfig
	cp $(dir $<)/defconfig $(buildroot_initramfs_config)

$(buildroot_initramfs_sysroot_stamp): $(buildroot_initramfs_tar)
	mkdir -p $(buildroot_initramfs_sysroot)
	tar -xpf $< -C $(buildroot_initramfs_sysroot) --exclude ./dev --exclude ./usr/share/locale
	touch $@

$(linux_wrkdir)/.config: $(linux_defconfig) $(linux_srcdir)
	mkdir -p $(dir $@)
	cp -p $< $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
ifeq (,$(filter rv%c,$(ISA)))
	sed 's/^.*CONFIG_RISCV_ISA_C.*$$/CONFIG_RISCV_ISA_C=n/' -i $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
endif
ifeq ($(ISA),$(filter rv32%,$(ISA)))
	sed 's/^.*CONFIG_ARCH_RV32I.*$$/CONFIG_ARCH_RV32I=y/' -i $@
	sed 's/^.*CONFIG_ARCH_RV64I.*$$/CONFIG_ARCH_RV64I=n/' -i $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv olddefconfig
endif

$(vmlinux): $(linux_srcdir) $(linux_wrkdir)/.config $(target_gcc)
	$(MAKE) -C $< O=$(linux_wrkdir) \
		CONFIG_INITRAMFS_SOURCE="$(confdir)/initramfs.txt $(buildroot_initramfs_sysroot)" \
		CONFIG_INITRAMFS_ROOT_UID=$(shell id -u) \
		CONFIG_INITRAMFS_ROOT_GID=$(shell id -g) \
		ARCH=riscv \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		PATH=$(RVPATH) \
		vmlinux

.PHONY: initrd
initrd: $(initramfs)

$(initramfs).d: $(buildroot_initramfs_sysroot)
	$(linux_gen_initramfs) -l $@ $(buildroot_initramfs_sysroot)

$(initramfs): $(buildroot_initramfs_sysroot) $(vmlinux)
	cd $(linux_wrkdir) && \
		$(linux_gen_initramfs) \
		-o $@ -u $(shell id -u) -g $(shell id -g) \
		$(confdir)/initramfs.txt \
		$(buildroot_initramfs_sysroot)

$(vmlinux_stripped): $(vmlinux)
	PATH=$(RVPATH) $(target)-strip -o $@ $<

$(vmlinux_bin): $(vmlinux)
	PATH=$(RVPATH) $(target)-objcopy -O binary $< $@

.PHONY: linux-menuconfig
linux-menuconfig: $(linux_wrkdir)/.config
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv menuconfig
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv savedefconfig
	cp $(dir $<)/defconfig $(linux_defconfig)

$(platform_dtb) : $(platform_dts)
	dtc -O dtb -o $(platform_dtb) $(platform_dts)

$(opensbi_payload): $(opensbi_srcdir) $(vmlinux_bin) $(platform_dtb)
	rm -rf $(opensbi_wrkdir)
	mkdir -p $(opensbi_wrkdir)
	$(MAKE) -C $(opensbi_srcdir) O=$(opensbi_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) \
		PLATFORM_RISCV_ABI=$(ABI) PLATFORM_RISCV_ISA=$(ISA) \
		PLATFORM=nuclei/ux600 FW_PAYLOAD_PATH=$(vmlinux_bin) FW_PAYLOAD_FDT_PATH=$(platform_dtb)

$(buildroot_initramfs_sysroot): $(buildroot_initramfs_sysroot_stamp)

.PHONY: buildroot_initramfs_sysroot vmlinux
buildroot_initramfs_sysroot: $(buildroot_initramfs_sysroot)
vmlinux: $(vmlinux)

.PHONY: clean
clean:
	rm -rf -- $(wrkdir)

.PHONY: sim
sim: $(opensbi_payload)
	$(xlspike) --isa=$(ISA) $(opensbi_payload)


-include $(initramfs).d

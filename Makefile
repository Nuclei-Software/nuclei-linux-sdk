ISA ?= rv64imac
ABI ?= lp64
EXTERNAL_TOOLCHAIN ?= 1

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
platform_dtb := $(wrkdir)/nuclei_ux600.dtb

# The second option is the more standard version, however in
# the interest of reproducibility, use the buildroot version that
# we compile so as to minimize unepected surprises. 

platform_openocd_cfg := $(confdir)/openocd_hbird.cfg

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
linux_image := $(linux_wrkdir)/arch/riscv/boot/Image
vmlinux_stripped := $(linux_wrkdir)/vmlinux-stripped
vmlinux_bin := $(wrkdir)/vmlinux.bin

initramfs := $(wrkdir)/initramfs.cpio.gz

opensbi_srcdir := $(srcdir)/opensbi
opensbi_wrkdir := $(wrkdir)/opensbi
opensbi_payload := $(opensbi_wrkdir)/platform/nuclei/ux600/firmware/fw_payload.elf
opensbi_jumpbin := $(opensbi_wrkdir)/platform/nuclei/ux600/firmware/fw_jump.bin

freeloader_srcdir := $(srcdir)/freeloader
freeloader_wrkdir := $(srcdir)/freeloader
freeloader_elf := $(freeloader_wrkdir)/freeloader.elf

uboot_srcdir := $(srcdir)/u-boot
uboot_wrkdir := $(wrkdir)/u-boot
uboot_bin := $(uboot_wrkdir)/u-boot.bin
uboot_dtb := $(uboot_wrkdir)/u-boot.dtb
uboot_mkimage := $(uboot_wrkdir)/tools/mkimage

uboot_cmd := $(confdir)/uboot.cmd

# Directory for boot images stored in sdcard
boot_wrkdir := $(wrkdir)/boot
boot_zip := $(wrkdir)/boot.zip
boot_ubootscr := $(boot_wrkdir)/boot.scr
boot_uimage := $(boot_wrkdir)/uImage
boot_initrd := $(boot_wrkdir)/initrd.img
boot_uimage_lz4 := $(boot_wrkdir)/uImage.lz4
boot_initrd_lz4 := $(boot_wrkdir)/initrd.lz4

# xlspike is prebuilt and installed to PATH
xlspike := xl_spike

# openocd is prebuilt and installed to PATH
openocd := openocd

target_gcc := $(CROSS_COMPILE)gcc
target_gdb := $(CROSS_COMPILE)gdb

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

$(linux_image): $(linux_srcdir) $(linux_wrkdir)/.config $(target_gcc)
	$(MAKE) -C $< O=$(linux_wrkdir) \
		CONFIG_INITRAMFS_ROOT_UID=$(shell id -u) \
		CONFIG_INITRAMFS_ROOT_GID=$(shell id -g) \
		ARCH=riscv \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		PATH=$(RVPATH) \
		Image

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

$(opensbi_jumpbin):
	rm -rf $(opensbi_wrkdir)
	$(MAKE) -C $(opensbi_srcdir) O=$(opensbi_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) \
		PLATFORM_RISCV_ABI=$(ABI) PLATFORM_RISCV_ISA=$(ISA) \
		PLATFORM=nuclei/ux600

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

.PHONY: bootimages
bootimages: $(boot_zip)

$(boot_wrkdir):
	mkdir -p $@

$(boot_ubootscr): $(uboot_cmd) $(uboot_mkimage)
	$(uboot_mkimage) -A riscv -T script -O linux -C none -a 0 -e 0 -n "bootscript" -d $(uboot_cmd) $@

$(boot_uimage_lz4): $(linux_image)
	$(uboot_mkimage) -A riscv -O linux -T kernel -C none -a 0xa0200000 -e 0xa0200000 -n Linux -d $< $(boot_uimage)
	lz4 $(boot_uimage) $@ -f -2

$(boot_initrd_lz4): $(buildroot_initramfs_sysroot)
	cd $(buildroot_initramfs_sysroot) && find . | fakeroot cpio -H newc -o > $(boot_wrkdir)/initrd.cpio
	$(uboot_mkimage) -A riscv -T ramdisk -C none -n Initrd -d $(boot_wrkdir)/initrd.cpio $(boot_initrd)
	lz4 $(boot_initrd) $@ -f -3

$(boot_zip): $(boot_wrkdir) $(boot_ubootscr) $(boot_uimage_lz4) $(boot_initrd_lz4)
	cd $(boot_wrkdir) && zip -q -r $(boot_zip) .

.PHONY: uboot
uboot: $(uboot_bin)

$(uboot_wrkdir)/.config: $(uboot_srcdir)
	mkdir -p $(uboot_wrkdir)
	make -C $(uboot_srcdir) O=$(uboot_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) nuclei_hbird_defconfig

$(uboot_dtb): $(uboot_bin)
$(uboot_mkimage) $(uboot_bin): $(uboot_srcdir) $(uboot_wrkdir)/.config
	make -C $(uboot_srcdir) O=$(uboot_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) all

.PHONY: freeloader

freeloader: $(freeloader_elf)

$(freeloader_elf): $(freeloader_srcdir) $(uboot_bin) $(opensbi_jumpbin)
	make -C $(freeloader_srcdir) ARCH=$(ISA) ABI=$(ABI) CROSS_COMPILE=$(CROSS_COMPILE) \
		FW_JUMP_BIN=$(opensbi_jumpbin) UBOOT_BIN=$(uboot_bin) DTB=$(uboot_dtb)

upload_freeloader: $(freeloader_elf)
	$(target_gdb) $< -ex "set remotetimeout 240" \
        -ex "target remote | $(openocd) --pipe -f $(platform_openocd_cfg)" \
        --batch -ex "monitor reset halt" -ex "monitor halt" \
	-ex "monitor flash protect 0 0 last off" -ex "load" \
	-ex "monitor resume" -ex "monitor shutdown" -ex "quit"

.PHONY: clean clean_boot cleanlinux cleanfreeloader cleanopensbi
clean: cleanfreeloader
	rm -rf -- $(wrkdir)

cleanboot:
	rm -rf -- $(boot_wrkdir) $(boot_zip)

cleanlinux:
	rm -rf -- $(linux_wrkdir) $(vmlinux_bin)

cleanfreeloader:
	make -C $(freeloader_srcdir) clean

cleanopensbi:
	rm -rf -- $(opensbi_wrkdir)

.PHONY: sim
sim: $(opensbi_payload)
	$(xlspike) --isa=$(ISA) $(opensbi_payload)


-include $(initramfs).d

# Makefile Variable SOC
## SOC Supported:
## demosoc: Nuclei Demo SoC used for evaluation
## evalsoc: Nuclei Evaluation SoC
SOC ?= evalsoc

## Makefile Variable CORE
## CORE Supported:
## ux600/ux900: rv64imac, lp64
## ux600fd/ux900fd: rv64imafdc, lp64d
CORE ?= ux900fd

## Makefile Variable ARCH_EXT
## ARCH_EXT can be b/p/v, eg. bp, bpv, pv, v
ARCH_EXT ?=

## Makefile Variable BOOT_MODE
## BOOT_MODE Supported:
## sd: boot from flash + sdcard, extra SDCard is required(kernel, rootfs, dtb placed in it)
## flash: boot from flash only, flash will contain images placed in sdcard of sd boot mode
BOOT_MODE ?= sd
## QEMU Disk Size in MBytes
## DISK_SIZE should >= 64
DISK_SIZE ?= 1024

# Include Nuclei RISC-V Core Makefile
include Makefile.core

CORE_UPPER = $(shell echo $(CORE) | tr 'a-z' 'A-Z')
check_item_exist = $(strip $(if $(filter 1, $(words $(1))),$(filter $(1), $(sort $(2))),))
CORE_ARCH_ABI = $($(CORE_UPPER)_CORE_ARCH_ABI)
ifneq ($(words $(CORE_ARCH_ABI)), 2)
$(warning Here we only support these cores: $(SUPPORTED_CORES))
$(error There is no coresponding ARCH_ABI setting for CORE $(CORE), please check Makefile.core)
endif

# Set ISA and ABI
ISA := $(word 1, $(CORE_ARCH_ABI))
ABI := $(word 2, $(CORE_ARCH_ABI))

ifneq ($(findstring 32,$(ABI)),)
XLEN := 32
else
XLEN := 64
endif

srcdir := $(dir $(realpath $(lastword $(MAKEFILE_LIST))))
srcdir := $(srcdir:/=)
wrkdir_root := $(CURDIR)/work

# Set confdir and workdir for different SoC
confdir := $(srcdir)/conf/$(SOC)
wrkdir := $(wrkdir_root)/$(SOC)
gendir := $(srcdir)/GENERATED
backupdir := $(gendir)/backup/$(SOC)
releasedir := $(gendir)/release
snapshotdir := $(gendir)/snapshot
gentimestamp := $(shell date -u +"%Y%m%dT%H%M%S")
gengitdesver := $(shell which git >/dev/null && git describe --always --abbrev=10 --dirty 2>/dev/null)
backupdir_snap := $(backupdir)/prebuilt_$(SOC)_$(shell date -u +"%Y%m%d-%H%M%S").zip
sourcezip_snap := $(snapshotdir)/snapshot_$(gentimestamp)_$(gengitdesver).zip

buildroot_srcdir := $(srcdir)/buildroot
buildroot_initramfs_wrkdir := $(wrkdir)/buildroot_initramfs

RISCV ?= $(buildroot_initramfs_wrkdir)/host
RVPATH := $(RISCV)/bin:$(PATH)

platform_dts := $(confdir)/nuclei_$(ISA).dts
platform_preproc_dts := $(wrkdir)/nuclei_$(ISA).dts.preprocessed
platform_dtb := $(wrkdir)/nuclei_$(ISA).dtb
platform_sim_dts := $(confdir)/nuclei_$(ISA)_sim.dts
platform_preproc_sim_dts := $(wrkdir)/nuclei_$(ISA)_sim.dts.preprocessed
platform_sim_dtb := $(wrkdir)/nuclei_$(ISA)_sim.dtb

platform_openocd_cfg := $(confdir)/openocd.cfg

buildroot_initramfs_config := $(confdir)/buildroot_initramfs_$(ISA)_config

buildroot_initramfs_tar := $(buildroot_initramfs_wrkdir)/images/rootfs.tar
buildroot_initramfs_sysroot_stamp := $(wrkdir)/.buildroot_initramfs_sysroot
buildroot_initramfs_sysroot := $(wrkdir)/buildroot_initramfs_sysroot

linux_srcdir := $(srcdir)/linux
linux_wrkdir := $(wrkdir)/linux
linux_defconfig := $(confdir)/linux_$(ISA)_defconfig
linux_gen_initramfs=$(linux_srcdir)/usr/gen_initramfs.sh

vmlinux := $(linux_wrkdir)/vmlinux
vmlinux_sim := $(linux_wrkdir)/vmlinux_sim
linux_image := $(linux_wrkdir)/arch/riscv/boot/Image
vmlinux_stripped := $(linux_wrkdir)/vmlinux-stripped
vmlinux_bin := $(wrkdir)/vmlinux.bin
vmlinux_sim_bin := $(wrkdir)/vmlinux_sim.bin

initramfs := $(wrkdir)/initramfs.cpio.gz

opensbi_srcdir := $(srcdir)/opensbi
opensbi_wrkdir := $(wrkdir)/opensbi
opensbi_plat_confdir := $(confdir)/opensbi
opensbi_plat_srcdir := $(srcdir)/opensbi/platform/nuclei/$(SOC)
opensbi_payload := $(opensbi_wrkdir)/platform/nuclei/$(SOC)/firmware/fw_payload.elf
opensbi_jumpbin := $(opensbi_wrkdir)/platform/nuclei/$(SOC)/firmware/fw_jump.bin
opensbi_jumpelf := $(opensbi_wrkdir)/platform/nuclei/$(SOC)/firmware/fw_jump.elf

opensbi_plat_deps := $(wildcard $(addprefix $(opensbi_plat_confdir)/, *.mk *.c *.h))

freeloader_srcdir := $(srcdir)/freeloader
freeloader_wrkdir := $(wrkdir)/freeloader
freeloader_confmk := $(confdir)/freeloader.mk
freeloader_elf := $(freeloader_wrkdir)/freeloader.elf

uboot_srcdir := $(srcdir)/u-boot
uboot_wrkdir := $(wrkdir)/u-boot
uboot_config := $(confdir)/uboot_$(ISA)_$(BOOT_MODE)_config
uboot_bin := $(uboot_wrkdir)/u-boot.bin
uboot_elf := $(uboot_wrkdir)/u-boot
uboot_mkimage := $(uboot_wrkdir)/tools/mkimage

uboot_cmd := $(confdir)/uboot.cmd

# Directory for boot images stored in sdcard
boot_wrkdir := $(wrkdir)/boot
boot_zip := $(wrkdir)/boot.zip
boot_ubootscr := $(boot_wrkdir)/boot.scr
boot_image := $(boot_wrkdir)/Image.lz4
boot_uimage_lz4 := $(boot_wrkdir)/uImage.lz4
boot_uinitrd_lz4 := $(boot_wrkdir)/uInitrd.lz4
boot_kernel_dtb := $(boot_wrkdir)/kernel.dtb

# qemu related disk image
qemu_disk := $(wrkdir)/disk.img

buildstamp_txt := $(wrkdir)/buildstamp.txt
fullboot_zip := $(wrkdir)/bootimages.zip

# Files need to backup
BACKUPMSG := $(wrkdir)/README.txt
RUNLOG := $(wrkdir)/run.log
FULL_BACKUPMSG := $(backupdir)/README.txt
FILES2BACKUP := $(boot_zip) $(uboot_elf) $(freeloader_elf) $(vmlinux) $(linux_image) \
	$(platform_preproc_dts) $(platform_dtb) $(opensbi_jumpelf) $(opensbi_payload) $(initramfs) \
	$(addsuffix /.config, $(uboot_wrkdir) $(linux_wrkdir) $(buildroot_initramfs_wrkdir)) \
	$(RUNLOG) $(BACKUPMSG)

FILES2BACKUP := $(subst $(realpath $(srcdir))/,, $(realpath $(FILES2BACKUP)))

# Include SoC related Makefile
include $(confdir)/build.mk

ifeq ($(XLEN),64)
target := riscv-nuclei-linux-gnu
else
target := riscv32-buildroot-linux-gnu
endif
CROSS_COMPILE := $(RISCV)/bin/$(target)-

amp_bins = $(CORE1_APP_BIN) $(CORE2_APP_BIN) $(CORE3_APP_BIN) $(CORE4_APP_BIN) $(CORE5_APP_BIN) $(CORE6_APP_BIN) $(CORE7_APP_BIN)

# Freq defines for dts preprocessing
DTS_DEFINES :=
ifneq ($(TIMER_HZ),)
DTS_DEFINES += -DTIMERCLK_FREQ=$(TIMER_HZ)
endif
ifneq ($(CPU_HZ),)
DTS_DEFINES += -DCPUCLK_FREQ=$(CPU_HZ)
endif
ifneq ($(PERIPH_HZ),)
DTS_DEFINES += -DPERIPHCLK_FREQ=$(PERIPH_HZ)
endif
ifneq ($(SIMULATION),)
DTS_DEFINES += -DSIMULATION=$(SIMULATION)
endif

# xlspike is prebuilt and installed to PATH
xlspike := xl_spike

# openocd is prebuilt and installed to PATH
openocd := openocd

# qemu is prebuild and installed to PATH
qemu := qemu-system-riscv$(XLEN)

## Makefile Variable GDBREMOTE
# You can change GDBREMOTE to other gdb remotes
## eg. if you have started openocd server with (bindto 0.0.0.0 defined in openocd.cfg)
## make sure your machine can connect to remote machine
## in remote machine(ipaddr 192.168.43.199) which connect the hardware board,
## then you can change the GDBREMOTE to 192.168.43.199:3333
## GDBREMOTE ?= 192.168.43.199:3333
GDBREMOTE ?= | $(openocd) -c \"gdb_port pipe; log_output openocd.log\" -f $(platform_openocd_cfg)

target_gcc := $(CROSS_COMPILE)gcc
target_gdb := $(CROSS_COMPILE)gdb

.PHONY: all help
all: help

help:
	@echo "Current build configuration: SOC=$(SOC) CORE=$(CORE) BOOT_MODE=$(BOOT_MODE) RISCV_ARCH=$(ISA) RISCV_ABI=$(ABI)"
	@echo "Here is a list of make targets supported"
	@echo ""
	@echo "- buildroot_initramfs-menuconfig : run menuconfig for buildroot, configuration will be saved into conf/$(SOC)"
	@echo "- buildroot_busybox-menuconfig : run menuconfig for busybox in buildroot, configuration is not saved into conf/$(SOC)"
	@echo "- linux-menuconfig : run menuconfig for linux kernel, configuration will be saved into conf/$(SOC)"
	@echo "- uboot-menuconfig : run menuconfig for uboot, configuration will be saved into conf/$(SOC)"
	@echo "- buildroot_initramfs_sysroot : generate rootfs directory using buildroot"
	@echo "- initrd : generate initramfs cpio file"
	@echo "- bootimages : generate boot images for SDCard"
	@echo "- freeloader : generate freeloader(first stage loader) run in norflash"
	@echo "- upload_freeloader : upload freeloader into development board using openocd and gdb"
	@echo "- debug_freeloader : connect to board, and debug it using openocd and gdb"
	@echo "- run_openocd : Run openocd to connect hardware board and start gdb server"
	@echo "- linux : build linux image"
	@echo "- opensbi : build opensbi jump binary"
	@echo "- uboot : build uboot and generate uboot binary"
	@echo "- clean : clean this full workspace"
	@echo "- cleanboot : clean generated boot images"
	@echo "- cleanlinux : clean linux workspace"
	@echo "- cleanbuildroot : clean buildroot workspace"
	@echo "- cleansysroot : clean buildroot sysroot files"
	@echo "- cleanuboot : clean u-boot workspace"
	@echo "- cleanfreeloader : clean freeloader generated objects"
	@echo "- cleanopensbi : clean opensbi workspace"
	@echo "- backup : backup generated prebuilt images into $(backupdir) folder, you need to input backup message when this target is triggered"
	@echo "- snapshot : snapshot linux sdk source code into $(snapshotdir) folder, this snapshot zip files will not contain any vcs control files"
ifeq ($(SOC),demosoc)
	@echo "- preboot : If you run sim target before, and want to change to bootimages target, run this to prepare environment"
	@echo "- presim : If you run bootimages target before, and want to change to sim target, run this to prepare environment"
	@echo "- sim : run opensbi + linux payload in simulation using xl_spike"
endif
	@echo ""
	@echo "Main targets used frequently depending on your user case"
	@echo "If you want to run linux on development board, please run preboot, freeloader, bootimages targets"
ifeq ($(SOC),demosoc)
	@echo "If you want to run linux in simulation, please run presim, sim targets"
	@echo "Deprecated: The xl-spike support will be deprecated in future release"
endif


$(target_gcc): buildroot_initramfs_sysroot

$(wrkdir):
	mkdir -p $@

$(buildroot_initramfs_wrkdir)/.config:
	rm -rf $(dir $@)
	mkdir -p $(dir $@)
	cp $(buildroot_initramfs_config) $@
	$(MAKE) -C ${buildroot_srcdir} RISCV=$(RISCV) O=$(buildroot_initramfs_wrkdir) olddefconfig

# buildroot_initramfs provides gcc
$(buildroot_initramfs_tar): $(buildroot_srcdir) $(buildroot_initramfs_wrkdir)/.config $(buildroot_initramfs_config)
	$(MAKE) -C $< RISCV=$(RISCV) O=$(buildroot_initramfs_wrkdir)

.PHONY: buildroot_initramfs-menuconfig
buildroot_initramfs-menuconfig: $(buildroot_initramfs_wrkdir)/.config $(buildroot_srcdir)
	$(MAKE) -C $(dir $<) O=$(buildroot_initramfs_wrkdir) menuconfig
	$(MAKE) -C $(dir $<) O=$(buildroot_initramfs_wrkdir) savedefconfig
	cp $(dir $<)/defconfig $(buildroot_initramfs_config)

.PHONY: buildroot_busybox-menuconfig
buildroot_busybox-menuconfig: $(buildroot_initramfs_wrkdir)/.config $(buildroot_srcdir) $(target_gcc)
	$(MAKE) -C $(dir $<) O=$(buildroot_initramfs_wrkdir) busybox-menuconfig

$(buildroot_initramfs_sysroot_stamp): $(buildroot_initramfs_tar)
	mkdir -p $(buildroot_initramfs_sysroot)
	tar -xpf $< -C $(buildroot_initramfs_sysroot) --exclude ./dev --exclude ./usr/share/locale
	touch $@

.PHONY: initrd linux

$(linux_wrkdir)/.config: $(linux_defconfig) $(target_gcc)
	mkdir -p $(dir $@)
	cp -p $< $@
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) olddefconfig

$(vmlinux): linux

$(linux_image): linux
	@echo "Linux image is generated $@"

initrd: $(initramfs)
	@echo "initramfs cpio file is generated into $<"

linux: $(linux_wrkdir)/.config
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) \
		CONFIG_INITRAMFS_ROOT_UID=$(shell id -u) \
		CONFIG_INITRAMFS_ROOT_GID=$(shell id -g) \
		ARCH=riscv \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		PATH=$(RVPATH) \
		vmlinux Image

$(initramfs): $(buildroot_initramfs_sysroot) $(linux_image)
	$(INITRAMFS_PRECMD)
	cd $(linux_wrkdir) && \
		$(linux_gen_initramfs) \
		-o $@ -u $(shell id -u) -g $(shell id -g) \
		$(confdir)/initramfs.txt \
		$(buildroot_initramfs_sysroot)

$(vmlinux_stripped): $(vmlinux)
	PATH=$(RVPATH) $(target)-strip -o $@ $<

$(vmlinux_bin): $(vmlinux)
	PATH=$(RVPATH) $(target)-objcopy -O binary $< $@

ifeq ($(SOC),demosoc)
$(vmlinux_sim): $(linux_wrkdir)/.config
	$(MAKE) -C $(linux_srcdir) O=$(linux_wrkdir) \
		CONFIG_INITRAMFS_SOURCE="$(confdir)/initramfs.txt $(buildroot_initramfs_sysroot)" \
		CONFIG_INITRAMFS_ROOT_UID=$(shell id -u) \
		CONFIG_INITRAMFS_ROOT_GID=$(shell id -g) \
		ARCH=riscv \
		CROSS_COMPILE=$(CROSS_COMPILE) \
		PATH=$(RVPATH) \
		vmlinux
	cp -f $(vmlinux) $@

$(vmlinux_sim_bin): $(vmlinux_sim)
	PATH=$(RVPATH) $(target)-objcopy -O binary $< $@
endif

.PHONY: linux-menuconfig gen-dts gen-simdts
linux-menuconfig: $(linux_wrkdir)/.config
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) menuconfig
	$(MAKE) -C $(linux_srcdir) O=$(dir $<) ARCH=riscv CROSS_COMPILE=$(CROSS_COMPILE) savedefconfig
	cp $(dir $<)/defconfig $(linux_defconfig)

$(platform_preproc_dts): gen-dts
	echo "Platform preprocessed dts located in $(platform_preproc_dts), processed with defines $(DTS_DEFINES)"

gen-dts: $(platform_dts) $(target_gcc)
	$(target_gcc) -E -nostdinc -undef -x assembler-with-cpp $(DTS_DEFINES) $(platform_dts) -o $(platform_preproc_dts)

$(platform_preproc_sim_dts): gen-simdts
	echo "Platform sim preprocessed dts located in $(platform_preproc_sim_dts), processed with defines $(DTS_DEFINES)"

gen-simdts: $(platform_sim_dts) $(target_gcc)
	$(target_gcc) -E -nostdinc -undef -x assembler-with-cpp $(DTS_DEFINES) $(platform_sim_dts) -o $(platform_preproc_sim_dts)

$(platform_dtb) : $(platform_preproc_dts) $(target_gcc)
	dtc -O dtb -o $(platform_dtb) $(platform_preproc_dts)

$(platform_sim_dtb) : $(platform_preproc_sim_dts) $(target_gcc)
	dtc -O dtb -o $(platform_sim_dtb) $(platform_preproc_sim_dts)

.PHONY: opensbi opensbi_cp_plat

$(opensbi_jumpbin): opensbi

opensbi: $(target_gcc) $(opensbi_plat_deps)
	mkdir -p $(opensbi_plat_srcdir)
	cp -u $(opensbi_plat_confdir)/* $(opensbi_plat_srcdir)
	$(MAKE) -C $(opensbi_srcdir) O=$(opensbi_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) \
		PLATFORM_RISCV_ABI=$(ABI) PLATFORM_RISCV_ISA=$(ISA) PLATFORM=nuclei/$(SOC)

ifeq ($(SOC),demosoc)
$(opensbi_payload): $(opensbi_srcdir) $(vmlinux_sim_bin) $(platform_sim_dtb) $(opensbi_plat_deps)
	rm -rf $(opensbi_wrkdir)
	mkdir -p $(opensbi_wrkdir)
	mkdir -p $(opensbi_plat_srcdir)
	cp -u $(opensbi_plat_confdir)/* $(opensbi_plat_srcdir)
	$(MAKE) -C $(opensbi_srcdir) O=$(opensbi_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) \
		PLATFORM_RISCV_ABI=$(ABI) PLATFORM_RISCV_ISA=$(ISA) PLATFORM=nuclei/$(SOC) \
		FW_PAYLOAD_PATH=$(vmlinux_sim_bin) FW_FDT_PATH=$(platform_sim_dtb)
endif

$(buildroot_initramfs_sysroot): $(buildroot_initramfs_sysroot_stamp)

.PHONY: buildroot_initramfs_sysroot vmlinux
buildroot_initramfs_sysroot: $(buildroot_initramfs_sysroot)
vmlinux: $(vmlinux)

.PHONY: bootimages
bootimages: $(boot_zip)
	@echo "SDCard boot images are generated into $(boot_zip) and $(boot_wrkdir)"
	@echo "You can extract the $(boot_zip) to SDCard and insert the SDCard back to board"
	@echo "If freeloader is already flashed to board's norflash, then you can reset power of the board"
	@echo "Then you can open UART terminal with baudrate 115200, you will be able to see kernel boot message"

$(boot_wrkdir):
	mkdir -p $@

$(boot_ubootscr): $(uboot_cmd) $(uboot_mkimage)
	$(uboot_mkimage) -A riscv -T script -O linux -C none -a 0 -e 0 -n "bootscript" -d $(uboot_cmd) $@

# UIMAGE_AE_CMD is defined in conf/$(SOC)/build.mk
# For DDR_BASE = 0xA0000000, eg.
# UIMAGE_AE_CMD := -a 0xA0400000 -e 0xA0400000
$(boot_uimage_lz4): $(linux_image)
# workaround for xlen = 32 target, use uncompressed kernel image
# compressed kernel image, facing an uncompress error -93 in Uncompressing Kernel Image stage
ifeq ($(XLEN),32)
	#lz4 $< $(boot_image) -f -4
	cp $< $(boot_image)
	#gzip -1 -c $< > $(boot_image)
	$(uboot_mkimage) -A riscv -O linux -T kernel -C none $(UIMAGE_AE_CMD) -n Linux -d $(boot_image) $@
else
	lz4 $< $(boot_image) -f -9
	$(uboot_mkimage) -A riscv -O linux -T kernel -C lz4 $(UIMAGE_AE_CMD) -n Linux -d $(boot_image) $@
endif
	rm -f $(boot_image)

$(boot_uinitrd_lz4): $(initramfs)
	lz4 $(initramfs) $(initramfs).lz4 -f -9 -l
	$(uboot_mkimage) -A riscv -T ramdisk -C lz4 -n Initrd -d $(initramfs).lz4 $(boot_uinitrd_lz4)

$(boot_kernel_dtb): $(platform_preproc_dts)
	dtc -O dtb -o $(boot_kernel_dtb) $(platform_preproc_dts)

$(boot_zip): $(boot_wrkdir) $(boot_ubootscr) $(boot_uimage_lz4) $(boot_uinitrd_lz4) $(boot_kernel_dtb)
	rm -f $(boot_zip)
	cd $(boot_wrkdir) && zip -q -r $(boot_zip) .

.PHONY: uboot uboot-menuconfig
uboot: $(uboot_wrkdir)/.config
	$(MAKE) -C $(uboot_srcdir) O=$(uboot_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) all

uboot-menuconfig: $(uboot_wrkdir)/.config $(uboot_srcdir)
	$(MAKE) -C $(uboot_srcdir) O=$(uboot_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) menuconfig
	$(MAKE) -C $(uboot_srcdir) O=$(uboot_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) savedefconfig
	cp $(dir $<)/defconfig $(uboot_config)

$(uboot_wrkdir)/.config: $(target_gcc) $(uboot_config)
	mkdir -p $(uboot_wrkdir)
	cp $(uboot_config) $@
	$(MAKE) -C $(uboot_srcdir) O=$(uboot_wrkdir) CROSS_COMPILE=$(CROSS_COMPILE) olddefconfig

$(uboot_mkimage) $(uboot_bin): uboot
	@echo "Uboot binary is generated into $<"

.PHONY: freeloader upload_freeloader debug_freeloader run_openocd

freeloader: $(freeloader_elf)
	@echo "freeloader is generated in $(freeloader_elf)"
	@echo "You can download this elf into development board using make upload_freeloader"
	@echo "or using openocd and gdb to achieve it"
	@echo "If you want to use gdb and openocd to debug it"
	@echo "You can run make debug_freeloader to connect to the running target cpu"

ifeq ($(BOOT_MODE),flash)
# Internal used
.PHONY: prepare4m freeloader4m
prepare4m: buildroot_initramfs_sysroot
	find $(buildroot_initramfs_wrkdir)/build/ -type f -wholename "*busybox*/.config" | xargs sed -i '/CONFIG_STATIC/cCONFIG_STATIC=y'
	rm -rf $(buildroot_initramfs_wrkdir)/images/*
	rm -rf $(buildroot_initramfs_sysroot) $(buildroot_initramfs_sysroot_stamp)
	$(MAKE) -C $(buildroot_srcdir) O=$(buildroot_initramfs_wrkdir) busybox-rebuild
	$(MAKE) CORE=$(CORE) buildroot_initramfs_sysroot
	sed -i '/sbin\/getty/cconsole::respawn:/bin/sh' $(buildroot_initramfs_sysroot)/etc/inittab
	#sed -i '/init\.d/d' $(buildroot_initramfs_sysroot)/etc/inittab
	rm -rf $(buildroot_initramfs_sysroot)/lib/*
	$(MAKE) CORE=$(CORE) cleanboot bootimages

freeloader4m: prepare4m $(freeloader_elf)
	@echo "freeloader is generated in $(freeloader_elf)"
	@echo "You can download this elf into development board using make upload_freeloader"
	@echo "or using openocd and gdb to achieve it"
	@echo "File size of freeloader is as below:"
	size $(freeloader_elf)
	ls -lh $(freeloader_elf)
endif

ifeq ($(BOOT_MODE),sd)
$(freeloader_elf): $(freeloader_srcdir) $(uboot_bin) $(opensbi_jumpbin) $(platform_dtb) $(amp_bins)
else
$(freeloader_elf): $(freeloader_srcdir) $(uboot_bin) $(opensbi_jumpbin) $(platform_dtb) $(boot_zip) $(amp_bins)
endif
	mkdir -p  $(freeloader_wrkdir)
	$(MAKE) -C $(freeloader_srcdir) O=$(freeloader_wrkdir) ARCH=$(ISA) ABI=$(ABI) ARCH_EXT=$(ARCH_EXT) \
		BOOT_MODE=$(BOOT_MODE) CROSS_COMPILE=$(CROSS_COMPILE) \
		OPENSBI_BIN=$(opensbi_jumpbin) UBOOT_BIN=$(uboot_bin) DTB=$(platform_dtb) \
		KERNEL_BIN=$(boot_uimage_lz4) INITRD_BIN=$(boot_uinitrd_lz4) CONFIG_MK=$(freeloader_confmk)  \
		CORE1_APP_BIN=$(CORE1_APP_BIN) CORE2_APP_BIN=$(CORE2_APP_BIN) CORE3_APP_BIN=$(CORE3_APP_BIN) \
		CORE4_APP_BIN=$(CORE4_APP_BIN) CORE5_APP_BIN=$(CORE5_APP_BIN) CORE6_APP_BIN=$(CORE6_APP_BIN) CORE7_APP_BIN=$(CORE7_APP_BIN)

upload_freeloader: $(freeloader_elf)
	$(target_gdb) $< -ex "set remotetimeout 240" \
	-ex "target remote $(GDBREMOTE)" \
	--batch -ex "monitor reset halt" -ex "load" \
	-ex "monitor resume" -ex "quit"

# Please make sure freeloader, linux and uboot are generated
debug_freeloader:
	$(target_gdb) $(freeloader_elf) -ex "set remotetimeout 240" \
	-ex "target remote $(GDBREMOTE)" \
	-ex "set confirm off" -ex "add-symbol-file $(vmlinux)" \
	-ex "add-symbol-file $(opensbi_jumpelf)" \
	-ex "add-symbol-file $(uboot_elf)" -ex "set confirm on"

# Internal used
upload_sbipayload: $(opensbi_payload)
	$(target_gdb) $< -ex "set remotetimeout 240" \
	-ex "target remote $(GDBREMOTE)" \
	--batch -ex "monitor reset halt" -ex "load" \
	-ex "monitor resume" -ex "quit"

# Internal used, please make sure freeloader and linux are generated
debug_sbipayload:
	$(target_gdb) $(opensbi_payload) -ex "set remotetimeout 240" \
	-ex "target remote $(GDBREMOTE)" \
	-ex "set confirm off" -ex "add-symbol-file $(vmlinux)" \
	-ex "add-symbol-file $(opensbi_payload)" \
	-ex "set confirm on"

run_openocd:
	@echo "Start openocd server"
	$(openocd) -f $(platform_openocd_cfg)


.PHONY: distclean clean cleanboot cleanlinux cleanbuildroot cleansysroot cleanfreeloader  clean_freeloader cleanopensbi prepare presim preboot
distclean:
	rm -rf $(wrkdir_root)

clean: cleanfreeloader
	rm -rf $(wrkdir)

cleanboot:
	rm -rf $(boot_wrkdir) $(boot_zip) $(initramfs) $(initramfs).lz4

cleanlinux:
	rm -rf $(linux_wrkdir) $(vmlinux_bin) $(vmlinux_sim_bin)

cleanbuildroot:
	rm -rf $(buildroot_initramfs_wrkdir)

cleansysroot:
	rm -rf $(buildroot_initramfs_sysroot) $(buildroot_initramfs_sysroot_stamp)

cleanuboot:
	rm -rf $(uboot_wrkdir)

clean_freeloader: cleanfreeloader

cleanfreeloader:
	$(MAKE) -C $(freeloader_srcdir) O=$(freeloader_wrkdir) clean

cleanopensbi:
	rm -rf $(opensbi_wrkdir)


# If you change your make target from sim to bootimages, you need to run preboot first
preboot: prepare

prepare:
	rm -rf $(vmlinux_bin) $(vmlinux) $(linux_image) $(vmlinux_sim_bin) $(vmlinux_sim)

ifeq ($(SOC),demosoc)
.PHONY: sim opensbi_sim presim

# If you change your make target from bootimages to sim, you need to run presim first
presim: prepare
opensbi_sim: $(opensbi_payload)

sim: $(opensbi_payload)
	$(xlspike) --isa=$(ISA) $(opensbi_payload)
endif

.PHONY: gendisk run_qemu

gendisk: $(qemu_disk)
	@echo "QEMU SDCard Disk Image is generated to $(qemu_disk)"

$(qemu_disk): $(boot_zip)
	cd $(boot_wrkdir) && dd if=/dev/zero of=$(qemu_disk) bs=$(DISK_SIZE)M count=1
	echo "Please make sure mformat version is >= 4.0.24, current version $(shell mformat --version)"
	cd $(boot_wrkdir) && mformat -F -h 64 -s 32 -t $$(($(DISK_SIZE)-1)) :: -i $(qemu_disk) || rm -f $(qemu_disk)
	cd $(boot_wrkdir) && mcopy -i $(qemu_disk) boot.scr kernel.dtb uImage.lz4 uInitrd.lz4 :: || rm -f $(qemu_disk)

# workaround for demosoc: need to change TIMERCLK_FREQ for conf/demosoc/*.dts to 10000000
# limited feature for simulation demosoc is supported, don't expect full feature of demosoc
run_qemu: $(qemu_disk) $(freeloader_elf)
	@echo "Run on qemu for simulation"
	$(qemu) $(QEMU_MACHINE_OPTS) -cpu nuclei-$(CORE),ext=$(ARCH_EXT) -bios $(freeloader_elf) -nographic -drive file=$(qemu_disk),if=sd,format=raw

.PHONY: backup snapshot genstamp genboot
# backup your build
backup: $(wrkdir)
	mkdir -p $(backupdir)
	@echo "Backup SOC=$(SOC) built configs linux image, freeloader, opensbi, uboot, rootfs, dts and dtb into $(backupdir_snap)"
	@echo "Backup Date : $(shell date)" > $(BACKUPMSG)
	read -p 'Input your backup message: ' backupmsg ; echo "Backup messasge: $$backupmsg" >> $(BACKUPMSG)
	@echo "> git log --oneline -1" >> $(BACKUPMSG)
	git log --oneline -1 >> $(BACKUPMSG)
	@echo "> git describe  --always --abbrev=10 --dirty" >> $(BACKUPMSG)
	git describe  --always --abbrev=10 --dirty >> $(BACKUPMSG)
	@echo "> git status -b -s" >> $(BACKUPMSG)
	git status -b -s >> $(BACKUPMSG)
	@echo "> git submodule" >> $(BACKUPMSG)
	git submodule >> $(BACKUPMSG)
	zip -q -r $(backupdir_snap) $(FILES2BACKUP)
#	tar -czf $(backupdir_snap) $(FILES2BACKUP)
	@echo "\n-----------------------------------------" >> $(FULL_BACKUPMSG)
	@md5sum $(backupdir_snap) >> $(FULL_BACKUPMSG)
	@cat $(BACKUPMSG)  >> $(FULL_BACKUPMSG)
	@echo "empty content in run log file $(RUNLOG)"
	@echo "" > $(RUNLOG)

# snapshot source code
snapshot:
	@git-archive-all --version
	@echo "Archive linux sdk source code snapshot to $(sourcezip_snap)"
	@mkdir -p $(snapshotdir)
	git-archive-all --prefix=nuclei-linux-sdk $(sourcezip_snap)

# generate build stamp
genstamp: $(wrkdir)
	@echo "Record build date and build git information into $(buildstamp_txt)"
	@echo "Build Date : $(shell date)" > $(buildstamp_txt)
	@echo "Build Configuration: SOC=$(SOC) CORE=$(CORE) ARCH_EXT=$(ARCH_EXT) BOOT_MODE=$(BOOT_MODE)" >> $(buildstamp_txt)
	@echo "Repo Git Information:" >> $(buildstamp_txt)
	git log --oneline -1 >> $(buildstamp_txt)
	git describe  --always --abbrev=10 --dirty >> $(buildstamp_txt)
	git submodule >> $(buildstamp_txt)
	@echo "Repo Workspace Information:" >> $(buildstamp_txt)
	git status -b -s >> $(buildstamp_txt)

# generate boot images and freeloader zip
genboot: genstamp freeloader bootimages
	@rm -f $(fullboot_zip)
	cd $(wrkdir) && zip -q -r -j $(fullboot_zip) $(boot_zip) $(freeloader_elf) $(buildstamp_txt)
	@echo "SDCard boot images and freeloader elf are generated into $(fullboot_zip)"

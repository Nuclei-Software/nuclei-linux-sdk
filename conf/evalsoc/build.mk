FW_TEXT_START := 0x80000000
UIMAGE_AE_CMD := -a 0x80400000 -e 0x80400000
# Need Nuclei Qemu >= 2025.10
QEMU_MACHINE_OPTS := -M nuclei_evalsoc,download=flashxip,soc-cfg=$(confdir)/evalsoc.json,aia=aplic-imsic,aia-guests=4 -smp 1 -m 2G
# initramfs pre command before generate initrd ramfs
INITRAMFS_PRECMD := bash $(confdir)/preramfs.sh $(confdir) $(buildroot_initramfs_sysroot) copyfiles.txt
# eg. $(confdir)/amp/cx.bin
CORE1_APP_BIN :=
CORE2_APP_BIN :=
CORE3_APP_BIN :=
CORE4_APP_BIN :=
CORE5_APP_BIN :=
CORE6_APP_BIN :=
CORE7_APP_BIN :=

# Freq Settings
TIMER_HZ ?=
CPU_HZ ?=
PERIPH_HZ ?= $(CPU_HZ)
SIMULATION ?=

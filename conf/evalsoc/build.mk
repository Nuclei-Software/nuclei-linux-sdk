FW_TEXT_START := 0x80000000
UIMAGE_AE_CMD := -a 0x80400000 -e 0x80400000
# Need Nuclei Qemu >= 2023.10
ARCH_EXT := v_zfh_zvfh
QEMU_MACHINE_OPTS := -M nuclei_evalsoc,download=flashxip -smp 8 -m 2G
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
SIMULATION ?= 0

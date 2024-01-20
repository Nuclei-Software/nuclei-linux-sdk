FW_TEXT_START := 0x00000000
UIMAGE_AE_CMD := -a 0x0400000 -e 0x0400000
# qemu currently not work for customsoc, please don't use it
#QEMU_MACHINE_OPTS := -M nuclei_customsoc,download=flashxip -smp 1 -m 2G
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

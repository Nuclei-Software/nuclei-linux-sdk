FW_TEXT_START := 0xc0000000
OPTEE_OS_TZDRAM_START := 0xc0800000
OPTEE_OS_TZDRAM_SIZE := 0x800000
OPTEE_OS_SHMEM_START := 0xc0200000
OPTEE_OS_SHMEM_SIZE := 0x200000
OPTEE_PLIC_BASE := 0x4000000
# Need Nuclei Qemu >= 2023.10
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
SIMULATION ?=

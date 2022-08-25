UIMAGE_AE_CMD := -a 0xA0400000 -e 0xA0400000
# qemu currently not work for evalsoc
QEMU_MACHINE_OPTS := -M nuclei_u,download=flashxip -smp 8 -m 1.5G
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

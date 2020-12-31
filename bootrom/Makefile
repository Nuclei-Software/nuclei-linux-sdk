CROSS_COMPILE ?= riscv-nuclei-linux-gnu-
ARCH ?= rv64imac
ABI ?= lp64

CC = $(CROSS_COMPILE)gcc
OBJCOPY= $(CROSS_COMPILE)objcopy


CFLAGS = \
	-march=$(ARCH) -mabi=$(ABI) -mcmodel=medany \
	-nostdlib -nostartfiles -fno-common -std=gnu11 \
	-static \
	-fPIC \
	-O2 -g -Wall

O ?=.

# ^ consider taking out -g -Og and putting in -O2

bootloaders=\
	$(O)/bootrom.elf \
	$(O)/bootrom.bin

.PHONY: all
all: $(bootloaders)

.PHONY: clean
clean:
	rm -f $(bootloaders)

bootrom_sources = \
	./bootloader.S \
	./bootloader.c \
	./ed25519/*.c \
	./sha3/*.c

%.elf: $(bootrom_sources) bootloader.lds
	$(CC) $(CFLAGS) -I./ -L . -T bootloader.lds -o $@ $(bootrom_sources)

%.bin: %.elf
	$(OBJCOPY) -O binary --only-section=.text $< $@


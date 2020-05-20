# Nuclei Linux SDK

This builds a complete RISC-V cross-compile toolchain for the Nuclei UX600
RISC-V 64Bit Core.

It also builds linux kernel, device tree, ramdisk, and opensbi with linux kernel
payload for Nuclei xl-spike which can emulate Nuclei UX600 SoC.

It can also build linux kernel, ramdisk, opensbi and freeloader for Nuclei UX600
SoC FPGA bitstream running in Nuclei HummingBird FPGA Board.

## Tested Configurations

### Ubuntu 18.04 x86_64 host

- Status: Working
- Build dependencies: `build-essential git autotools texinfo bison flex
  libgmp-dev libmpfr-dev libmpc-dev gawk libz-dev libssl-dev device-tree-compiler`
- Get prebuilt toolchain and openocd from [Nuclei Development Tools](https://nucleisys.com/download.php)
- Setup openocd and add it into **PATH**

## Build Instructions

Checkout this repository. Then you will need to checkout all of the linked
submodules using:

`git submodule update --recursive --init`

This will take some time and require around 7GB of disk space. Some modules may
fail because certain dependencies don't have the best git hosting. The only
solution is to wait and try again later (or ask someone for a copy of that
source repository).

Once the submodules are initialized, run `make` and the complete toolchain
and images will be built. The completed build tree will consume about 14G of disk
space.

## Booting Linux on Nuclei xl-spike

**Note**: `xl_spike` tool should be installed and added into **PATH** in advance.
Contact with our sales via email contact@nucleisys.com to get `xl-spike` tools.

### Toolchain Setup
#### Build using external toolchain

If you want to build using prebuilt external toolchain provided by Nuclei,
you can run `export EXTERNAL_TOOLCHAIN=1` before do any make steps.

#### Build with internal buildroot toolchain

If you want to build using internal toolchain built by buildroot,
you can run `export EXTERNAL_TOOLCHAIN=0` before do any make steps.

### Run on xl_spike 

When toolchain steps are finished, then, you can build buildroot, linux and opensbi,
and run opensbi with linux payload on xlspike by running `make sim`.

## Booting Linux on [Nuclei HummingBird Board](https://nucleisys.com/developboard.php)

### Get Nuclei UX600 SoC MCS from Nuclei

Contact with our sales via email contact@nucleisys.com to get FPGA bitstream for Nuclei
UX600 SoC MCS and get guidance about how to program FPGA bitstream in the board.

### Build Freeloader

*freeloader* is a first stage bootloader which contains *opensbi*, *uboot* and *dtb* binaries,
when bootup, it will enable I/D cache and load *opensbi*, *uboot* and *dtb* from onboard
norflash to DDR, and then goto entry of *opensbi*.

To build *freeloader*, you just need to run `make freeloader`

### Upload Freeloader to HummingBird FPGA Board

If you have connected your board to your Linux development environment, and setuped JTAG drivers,
then you can run `make upload_freeloader` to upload the *freeloader/freeloader.elf* to your board.

You can use riscv-nuclei-elf-gdb and openocd to download this program by yourself.

### Build SDCard Boot Images

If the freeloader is flashed to the board, then you can prepare the SDCard boot materials,
you can run `make bootimages` to generate the boot images to *work/boot*, and an zip file
called *work/boot.zip* , you can copy this *boot.zip* file to your SDCard, and extract it,
then you can insert this SDCard to your SDCard slot beside the TFT LCD.

### Run Linux

When all above is done, you can reset the power on board, then opensbi will boot uboot, and
uboot will automatically load linux image and initramfs from SDCard and boot linux.

The linux login user name and password is *root* and *nuclei*.



## Notice

This repo is based on opensource repo https://github.com/sifive/freedom-u-sdk/tree/archive/buildroot

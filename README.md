# Nuclei Linux SDK

This builds a complete RISC-V cross-compile toolchain for the Nuclei UX600
RISC-V 64Bit Core. It also builds linux kernel, device tree, ramdisk, and
opensbi with linux kernel payload for Nuclei xl-spike which can emulate Nuclei
UX600 SoC.

## Tested Configurations

### Ubuntu 18.04 x86_64 host

- Status: Working
- Build dependencies: `build-essential git autotools texinfo bison flex
  libgmp-dev libmpfr-dev libmpc-dev gawk libz-dev libssl-dev device-tree-compiler`
- Additional build deps for QEMU: `libglib2.0-dev libpixman-1-dev`
- tools require for 'format-boot-loader' target: mtools

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

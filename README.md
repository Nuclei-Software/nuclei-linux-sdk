# Nuclei Linux SDK

This will download external prebuilt toolchain, and build linux kernel, device tree, ramdisk,
and opensbi with linux kernel payload for Nuclei xl-spike which can emulate Nuclei UX600 SoC.

It can also build linux kernel, rootfs ramdisk, opensbi and freeloader for Nuclei UX600
SoC FPGA bitstream running in Nuclei HummingBird FPGA Board.

> The rootfs used in this SDK is initramfs format.

> **Note**: This is a special version of Nuclei Linux SDK.
> * The kernel configuration and buildroot configuration are optimized to generate smaller image size.
> * freeloader in version will contain opensbi, uboot, kernel, rootfs and dtb binaries, so you
>   when you build freeloader, and downloaded it into onboard flash, then you will be able to
>   boot linux without SD card
> * The freeloader linker script is modified, the linker script flash size changed from 4MB to 8MB.
> * If you want to compile a normal version of freeloader, just follow [Build Freeloader](#build-freeloader), you will need to replace the onboard MCU-Flash(U24) to >= 8MB
> * When you are going to replace the onboard MCU Flash, please choose a compatiable one and also need to be [supported by Nuclei OpenOCD](https://github.com/riscv-mcu/riscv-openocd/blob/nuclei-cjtag/src/flash/nor/spi.c).
> * If you want to compile a 4MB version of freeloader, which you can put it into current board flash,
>   you can just follow [Build 4MB Freeloader](#build-4mb-freeloader) to achieve it.

## Tested Configurations

### Ubuntu 18.04 x86_64 host

- Status: Working
- Build dependencies: `build-essential git autotools-dev make cmake texinfo bison minicom flex liblz4-tool
  libgmp-dev libmpfr-dev libmpc-dev gawk libz-dev libssl-dev device-tree-compiler libncursesw5-dev libncursesw5`
- Get prebuilt openocd from [Nuclei Development Tools](https://nucleisys.com/download.php)
- Setup openocd and add it into **PATH**

## Build Instructions

### Install Dependencies

Install the software dependencies required by this SDK using command:

~~~shell
sudo apt-get install build-essential git autotools-dev cmake texinfo bison minicom flex liblz4-tool \
   libgmp-dev libmpfr-dev libmpc-dev gawk libz-dev libssl-dev device-tree-compiler libncursesw5-dev libncursesw5
~~~

### Install Nuclei Tools

Download prebuilt 64bit `openocd` tool from [Nuclei Development Tools](https://nucleisys.com/download.php),
and extract it into your PC, and then setup **PATH** using this command:

~~~shell
# Make sure you changed /path/to/openocd/bin to the real path of your PC
export PATH=/path/to/openocd/bin:$PATH
# Check path is set correctly
which openocd
~~~

### Clone Repo

* Checkout this repository and checkout `dev_nuclei_flash` branch using `git`.

  - If you have good network access to github, you can clone this repo using command
    `git clone -b dev_nuclei_flash https://github.com/Nuclei-Software/nuclei-linux-sdk`
  - Otherwise, you can try with our mirror maintained in gitee using command
    `git clone -b dev_nuclei_flash https://gitee.com/Nuclei-Software/nuclei-linux-sdk`

* Then you will need to checkout all of the linked submodules using:

  ~~~shell
  cd nuclei-linux-sdk
  git submodule update --recursive --init
  ~~~

* To make sure you have checked out clean source code, you need to run `git status` command,
  and get expected output as below:

  ~~~
  On branch dev_nuclei_flash
  Your branch is up to date with 'origin/dev_nuclei_flash'.

  nothing to commit, working tree clean
  ~~~

* If you have trouble in get clean working tree, you can try command
  `git submodule update --recursive --init` again, you might need to
  retry several times depending on your network access speed.

This will take some time and require around 2GB of disk space. Some modules may
fail because certain dependencies don't have the best git hosting. The only
solution is to wait and try again later (or ask someone for a copy of that
source repository).

### Update source code

Update source code if there are new commits in this repo.

Assume currently you are in `dev_nuclei_flash` branch, and **the working tree is clean**.

Then you run the following command to update this repo:

~~~shell
# Pull lastest source code and rebase your local commits onto it
git pull --rebase origin dev_nuclei_flash
# Update git submodules
git submodule update
# Check workspace status to see whether it is clean
git status
~~~

## Select UX600 Core Configuration

You can choose different core configuration by modify the `CORE ?= ux600` line in `Makefile`.

We support two configurations for **CORE**:

* `ux600`: rv64imac core configuration without FPU.
* `ux600fd`: rv64imafdc core configuration with FPU.

Please modify the `Makefile` to your correct core configuration before build any source code.

* If you want to compile and run using simulator *xl-spike*, please
  check steps mentioned in **Booting Linux on Nuclei xl-spike**
* If you want to compile and run using FPGA evaluation board, please
  check steps mentioned in **Booting Linux on Nuclei HummingBird Board**

## Booting Linux on Nuclei xl-spike

**Note**: `xl_spike` tool should be installed and added into **PATH** in advance.
Contact with our sales via email contact@nucleisys.com to get `xl-spike` tools.

### Run on xl_spike

If you have run `make bootimages` command before, please make sure you run `make presim` to prepare
build environment for running linux in simulation.

When toolchain steps are finished, then, you can build buildroot, linux and opensbi,
and run opensbi with linux payload on xlspike by running `make sim`.

Here is sample output running in xl_spike:

~~~
xl_spike --isa=rv64imac /home/hqfang/workspace/software/nuclei-linux-sdk/work/opensbi/platform/nuclei/ux600/firmware/fw_payload.elf
rv64 file
warning: tohost and fromhost symbols not in ELF; can't communicate with target
UART:
UART: OpenSBI v0.7
UART:    ____                    _____ ____ _____
UART:   / __ \                  / ____|  _ \_   _|
UART:  | |  | |_ __   ___ _ __ | (___ | |_) || |
UART:  | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
UART:  | |__| | |_) |  __/ | | |____) | |_) || |_
UART:   \____/| .__/ \___|_| |_|_____/|____/_____|
UART:         | |
UART:         |_|
UART:
UART: Platform Name          : Nuclei UX600
UART: Platform HART Count    : 1
UART: Platform Features      : timer,mfdeleg
UART: Boot HART ID           : 0
UART: Boot HART ISA          : rv64imafdcpsu
UART: BOOT HART Features     : pmp,scountern,mcounteren,time
UART: Firmware Base          : 0xa0000000
UART: Firmware Size          : 76 KB
UART: Runtime SBI Version    : 0.2
UART:
UART: MIDELEG : 0x0000000000000222
UART: MEDELEG : 0x000000000000b109
UART: PMP0    : 0x00000000a0000000-0x00000000a001ffff (A)
UART: PMP1    : 0x0000000000000000-0x01ffffffffffffff (A,R,W,X)
UART: [    0.000000] OF: fdt: Ignoring memory range 0xa0000000 - 0xa0200000
UART: [    0.000000] Linux version 5.7.0 (hqfang@softserver) (gcc version 9.2.0 (GCC), GNU ld (GNU Binutils) 2.32) #1 Wed Jun 10 21:10:15 CST 2020
UART: [    0.000000] initrd not found or empty - disabling initrd
UART: [    0.000000] Zone ranges:
UART: [    0.000000]   DMA32    [mem 0x00000000a0200000-0x00000000afffffff]
UART: [    0.000000]   Normal   empty
UART: [    0.000000] Movable zone start for each node
UART: [    0.000000] Early memory node ranges
UART: [    0.000000]   node   0: [mem 0x00000000a0200000-0x00000000afffffff]
UART: [    0.000000] Initmem setup node 0 [mem 0x00000000a0200000-0x00000000afffffff]
UART: [    0.000000] software IO TLB: mapped [mem 0xabc7c000-0xafc7c000] (64MB)
UART: [    0.000000] SBI specification v0.2 detected
UART: [    0.000000] SBI implementation ID=0x1 Version=0x7
UART: [    0.000000] SBI v0.2 TIME extension detected
UART: [    0.000000] SBI v0.2 IPI extension detected
UART: [    0.000000] SBI v0.2 RFENCE extension detected
UART: [    0.000000] riscv: ISA extensions acim
UART: [    0.000000] riscv: ELF capabilities acim
UART: [    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 64135
UART: [    0.000000] Kernel command line: earlycon=sbi
UART: [    0.000000] Dentry cache hash table entries: 32768 (order: 6, 262144 bytes, linear)
UART: [    0.000000] Inode-cache hash table entries: 16384 (order: 5, 131072 bytes, linear)
UART: [    0.000000] Sorting __ex_table...
UART: [    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
UART: [    0.000000] Memory: 146772K/260096K available (1838K kernel code, 2408K rwdata, 2048K rodata, 35496K init, 221K bss, 113324K reserved, 0K cma-reserved)
UART: [    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
UART: [    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
UART: [    0.000000] plic: mapped 53 interrupts with 1 handlers for 2 contexts.
UART: [    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
UART: [    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
UART: [    0.004852] sched_clock: 64 bits at 32kHz, resolution 30517ns, wraps every 70368744171142ns
UART: [    2.173156] printk: console [hvc0] enabled
UART: [    2.239654] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
UART: [    2.359252] pid_max: default: 32768 minimum: 301
UART: [    2.534332] Mount-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
UART: [    2.626983] Mountpoint-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
UART: [    3.395141] devtmpfs: initialized
UART: [    4.013824] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
UART: [    4.130493] futex hash table entries: 256 (order: 0, 6144 bytes, linear)
UART: [    5.965118] clocksource: Switched to clocksource riscv_clocksource
UART: [  188.634948] workingset: timestamp_bits=62 max_order=16 bucket_order=0
UART: [  196.970764] io scheduler mq-deadline registered
UART: [  197.035217] io scheduler kyber registered
UART: [  229.307861] brd: module loaded
UART: [  234.758789] loop: module loaded
UART: [  235.074951] random: get_random_bytes called from init_oops_id+0x26/0x30 with crng_init=0
UART: [  253.481536] Freeing unused kernel memory: 35496K
UART: [  253.571990] Run /init as init process
UART: Starting syslogd: OK
UART: Starting klogd: OK
UART: Running sysctl: OK
UART: Starting mdev... OK
UART: modprobe: can't change directory to '/lib/modules': No such file or directory
UART:
UART: Welcome to Nuclei System Techology
nucleisys login: root
root
UART: Password: nuclei

UART:
UART: Login timed out after 60 seconds
UART:
UART: Welcome to Nuclei System Techology
nucleisys login:
~~~

## Booting Linux on [Nuclei HummingBird Board](https://nucleisys.com/developboard.php)

### Get Nuclei UX600 SoC MCS from Nuclei

Contact with our sales via email contact@nucleisys.com to get FPGA bitstream for Nuclei
UX600 SoC MCS and get guidance about how to program FPGA bitstream in the board.

### Build Freeloader on your demand

You can build different version of freeloader on your demand.

#### Build Freeloader

In this version, *freeloader* is a first stage bootloader which contains *opensbi*, *uboot*,
*kernel*, *rootfs* and *dtb* binaries, when bootup, it will enable I/D cache and load *opensbi*, *uboot*, *kernel*, *rootfs* and *dtb* from onboard norflash to DDR, and then goto entry of *opensbi*.

To build *freeloader*, you just need to run `make freeloader`

> * For this special version, no need to prepare the sdcard boot image, just `make freeloader`
> will be enough.
> * If you have run `make freeloader4m` command before, and want to switch back to normal size
> of rootfs, please run `make clean` first to clean the workspace.

#### Build 4MB Freeloader

If you want to build a freeloader which can be loaded to 4M Flash, you can run `make freeloader4m`
to achieve it, but when you want to switch back to normal configuration, you will need to clean this
workspace first via `make clean`.

> **NOTICE**:
>
> * For this specical 4MB version, the rootfs size is optimized down by removing all files in *lib*
> folder, and change the busybox in buildroot from dynamic version to static version, and login
> is disabled directly.
>
> * First run of `make freeloader4m` will do the rootfs optimization for you, then if you run
> `make freeloader`, it will still generate the 4MB version freeloader for you, unless you
> clean buildroot or all the workspace.
>
> * If you changed buildroot configuration or kernel configuration, the freeloader size might increase,
> and bigger than 4MB, please take care.
>
> * Since the *lib* in rootfs are deleted, so your application dynamic linked will not be able to run,
> please generate static linked version, or you can use the normal version.
>
> * For more details about how this 4MB freeloader is built, please directly look into the Makefile in this project.

### Upload Freeloader to HummingBird FPGA Board

If you have connected your board to your Linux development environment, and setuped JTAG drivers,
then you can run `make upload_freeloader` to upload the *freeloader/freeloader.elf* to your board.

You can use riscv-nuclei-elf-gdb and openocd to download this program by yourself.

> No need to do the **Build SDCard Boot Images** steps for run linux directly from MCU flash.
> In this version, `make freeloader` or `make freeloader4m` will generate boot images for you,
> you can also use this boot images with your old freeloader(contains freeloader, uboot and dtb only).

### Build SDCard Boot Images

If you have run `make sim` command before, please make sure you run `make preboot` to prepare
build environment for generate boot images.

If the freeloader is flashed to the board, then you can prepare the SDCard boot materials,
you can run `make bootimages` to generate the boot images to *work/boot*, and an zip file
called *work/boot.zip* , you can copy this *boot.zip* file to your SDCard, and extract it,
then you can insert this SDCard to your SDCard slot(J57) beside the TFT LCD.

> SDCard is recommended to use SDHC format.

### Run Linux

When all above is done, you can reset the power on board, then opensbi will boot uboot, and
uboot will automatically load linux image and initramfs from SDCard and boot linux.

The linux login user name and password is *root* and *nuclei*.

Sample output in **UART @ 57600bps, Data 8bit, Parity None, Stop Bits 1bit, No Flow Control**.

~~~
OpenSBI v0.7
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name       : Nuclei UX600
Platform Features   : timer,mfdeleg
Platform HART Count : 1
Boot HART ID        : 0
Boot HART ISA       : rv64imafdcpsu
BOOT HART Features  : pmp,scounteren,mcounteren,time
BOOT HART PMP Count : 16
Firmware Base       : 0xa0000000
Firmware Size       : 76 KB
Runtime SBI Version : 0.2

MIDELEG : 0x0000000000000222
MEDELEG : 0x000000000000b109
PMP0    : 0x00000000a0000000-0x00000000a001ffff (A)
PMP1    : 0x0000000000000000-0x0000007fffffffff (A,R,W,X)


U-Boot 2020.07-rc2-g89856aea41 (Jun 10 2020 - 22:35:06 +0800)

CPU:   rv64imac
Model: nuclei,ux600
DRAM:  256 MiB
Board: Initialized
MMC:   spi@10034000:mmc@0: 0
In:    console
Out:   console
Err:   console
Net:   No ethernet found.
Hit any key to stop autoboot:  0
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
345 bytes read in 190 ms (1000 Bytes/s)
## Executing script at a8100000
Loading kernel
2095520 bytes read in 40835 ms (49.8 KiB/s)
Loading ramdisk
19155731 bytes read in 358790 ms (51.8 KiB/s)
Loading dtb
2256 bytes read in 214 ms (9.8 KiB/s)
Starts booting from SD
## Booting kernel from Legacy Image at a1000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    2095456 Bytes = 2 MiB
   Load Address: a0200000
   Entry Point:  a0200000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at a8300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    19155667 Bytes = 18.3 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at a8000000
   Booting using the fdt blob at 0xa8000000
   Uncompressing Kernel Image
   Using Device Tree in place at 00000000a8000000, end 00000000a80038cf

Starting kernel ...

[    0.000000] OF: fdt: Ignoring memory range 0xa0000000 - 0xa0200000
[    0.000000] Linux version 5.7.0-01403-g3d77e6a8804a (xl_ci@softserver) (gcc version 9.2.0 (GCC), GNU ld (GNU Binutils) 2.32) #1 Thu Jun 11 15:46:17 CST 2020
[    0.000000] Initial ramdisk at: 0x(____ptrval____) (19155667 bytes)
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x00000000a0200000-0x00000000afffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x00000000a0200000-0x00000000afffffff]
[    0.000000] Initmem setup node 0 [mem 0x00000000a0200000-0x00000000afffffff]
[    0.000000] software IO TLB: mapped [mem 0xabc7b000-0xafc7b000] (64MB)
[    0.000000] SBI specification v0.2 detected
[    0.000000] SBI implementation ID=0x1 Version=0x7
[    0.000000] SBI v0.2 TIME extension detected
[    0.000000] SBI v0.2 IPI extension detected
[    0.000000] SBI v0.2 RFENCE extension detected
[    0.000000] riscv: ISA extensions acim
[    0.000000] riscv: ELF capabilities acim
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 64135
[    0.000000] Kernel command line: earlycon=sbi
[    0.000000] Dentry cache hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    0.000000] Inode-cache hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    0.000000] Sorting __ex_table...
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Memory: 162872K/260096K available (1838K kernel code, 2408K rwdata, 2048K rodata, 112K init, 221K bss, 97224K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
[    0.000000] plic: mapped 53 interrupts with 1 handlers for 2 contexts.
[    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000793] sched_clock: 64 bits at 32kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.388671] printk: console [hvc0] enabled
[    0.400207] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.422149] pid_max: default: 32768 minimum: 301
[    0.449981] Mount-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.467315] Mountpoint-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.651397] devtmpfs: initialized
[    0.763244] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.785278] futex hash table entries: 256 (order: 0, 6144 bytes, linear)
[    1.187774] clocksource: Switched to clocksource riscv_clocksource
[    1.346893] Trying to unpack rootfs image as initramfs...
[  111.023071] Freeing initrd memory: 18700K
[  111.087738] workingset: timestamp_bits=62 max_order=16 bucket_order=0
[  112.157379] io scheduler mq-deadline registered
[  112.169494] io scheduler kyber registered
[  119.163360] brd: module loaded
[  120.453826] loop: module loaded
[  120.493865] sifive_spi 10014000.spi: mapped; irq=1, cs=1
[  120.577636] sifive_spi 10034000.spi: mapped; irq=2, cs=1
[  120.730560] mmc_spi spi1.0: SD/MMC host mmc0, no DMA, no WP, no poweroff, cd polling
[  120.767211] random: get_random_bytes called from init_oops_id+0x26/0x30 with crng_init=0
[  120.895477] Freeing unused kernel memory: 112K
[  120.912078] Run /init as init process
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory

Welcome to Nuclei System Techology
nucleisys login: root
Password:
login[60]: root login on 'console'
# cat /proc/cpuinfo
processor       : 0
hart            : 0
isa             : rv64imac
mmu             : sv39

# uname -a
Linux nucleisys 5.7.0-01403-g3d77e6a8804a #1 Thu Jun 11 15:46:17 CST 2020 riscv64 GNU/Linux
# ls /
bin      init     linuxrc  opt      run      tmp
dev      lib      media    proc     sbin     usr
etc      lib64    mnt      root     sys      var
~~~

## Application Development

### Quick help

You can run `make help` to show quick help message about how to use this linux sdk.

For detailed usage about components like buildroot, linux kernel, opensbi or uboot, please

check [Reference](#Reference).

### Customize buildroot packages

You can customize buildroot packages to add or remove package in buildroot using command:

~~~shell
make buildroot_initramfs-menuconfig
~~~

The new configuration will be saved to `conf/` folder, for when a full rebuild of buildroot
is necessary, please check [this link](https://buildroot.org/downloads/manual/manual.html#full-rebuild).

* *conf/buildroot_initramfs_ux600_config*: The buildroot configuration for UX600
* *conf/buildroot_initramfs_ux600fd_config*: The buildroot configuration for UX600FD

By default, we add many packages in buildroot default configuration, you can remove the packages
you dont need in configuration to generate smaller rootfs, a full rebuild of SDK is required for
removing buildroot package.

### Customize kernel configuration

You can customize linux kernel configuration using command `make linux-menuconfig`, the new configuration will be saved to `conf` folder

* *conf/linux_defconfig*: The linux kernel configuration for UX600 or UX600FD
* *conf/nuclei_ux600.dts*: Device tree for UX600 used in hardware
* *conf/nuclei_ux600fd.dts*: Device tree for UX600FD used in hardware
* *conf/nuclei_ux600_sim.dts*: Device tree for UX600 used in simulation
* *conf/nuclei_ux600fd_sim.dts*: Device tree for UX600FD used in simulation

### Remove generated boot images

You can remove generated boot images using command `make cleanboot`.

### Prebuilt applications with RootFS

If you want to do application development in Linux with Hummingbird FPGA evaluation board, please
follow these steps.

Currently, SDCard is not working in Linux, so if you want to put your own application, and run it in
linux, you have to add your application into rootfs and rebuild it, and use the newly generated boot
images, and put it into SDCard.

For example, I would like to compile new `dhrystone` application and run it in linux.

0. Make sure you have built boot images, using `make bootimages`

1. Copy the old `dhrystone` source code from `work/buildroot_initramfs/build/dhrystone-2` to
   `work/buildroot_initramfs/build/dhrystone-3`

2. cd to `work/buildroot_initramfs/build/dhrystone-3`, and modify `Makefile` as below:

   ~~~makefile
   # Make sure you use the compiler in this path below
   CC = ../../host/bin/riscv-nuclei-linux-gnu-gcc
   CPPFLAGS += -DNO_PROTOTYPES=1 -DHZ=100
   # Customized optimization options
   CFLAGS +=  -O2 -flto -funroll-all-loops -finline-limit=600 \
            -ftree-dominator-opts -fno-if-conversion2 -fselective-scheduling \
            -fno-code-hoisting -fno-common -funroll-loops -finline-functions \
            -falign-functions=4 -falign-jumps=4 -falign-loops=4
   LDLIBS += -lm

   all: dhrystone

   dhrystone: dhry_1.o dhry_2.o
      $(CC) $(CFLAGS) $(LDFLAGS) -o $@ $^ $(LDLIBS)

   clean:
      rm -f *.o dhrystone

   .PHONY: all clean
   ~~~

3. Run `make clean all` to rebuild this `dhrystone`

4. Copy generated `dhrystone` to previous generated buildroot_initramfs_sysroot folder, using
   command `cp dhrystone ../../../buildroot_initramfs_sysroot/usr/bin/dhrystone_opt`

5. cd to Nuclei linux SDK root, and run `make preboot` to clean previously generated boot images.

6. Generate new boot images with `dhrystone_opt` application added using command `make bootimages`

7. Download the generated `work/boot.zip` and extract it right under the SDCard root.

8. If you have already flashed `freeloader` using openocd, then just insert the SDCard, and reboot the
   board, when board is power on, and linux kernel is up, you can run the application `dhrystone_opt` in
   linux shell.


### Put prebuilt applications into SDCard

In the lastest commits since 079414d, sdcard can be initialized successfully during kernel boot.

Sample console output of kernel init message for sdcard ready.

~~~
[  124.646575] mmcblk0: mmc0:0000 SA08G 7.21 GiB
[  125.242645]  mmcblk0: p1
~~~

> **Note**: Currently the sdcard driver is using polling mode as temporary workaround.

When you have login the linux system, you can run command below to check
whether sdcard is initialized successfully.

~~~sh
# ls -l /dev/mmc*
brw-rw----    1 root     root      179,   0 Jan  1 00:04 /dev/mmcblk0
brw-rw----    1 root     root      179,   1 Jan  1 00:04 /dev/mmcblk0p1
~~~

If there are **/dev/mmcblk0p1** devices, then you can mount sdcard in *mnt*
directory using command:

~~~sh
# Mount /dev/mmcblk0p1 into /mnt
mount -t vfat /dev/mmcblk0p1 /mnt
# Check whether sdcard is mounted successfully
ls -l /mnt
~~~

If you want to put your prebuilt applications into SDCard, you need to unmount
the sdcard first using `umount /mnt`, and then eject the sdcard from the tf slot, and then insert the sdcard to sdcard reader and connect to your PC, and copy your prebuilt applications into SDCard.

When your applications are placed into the sdcard correctly, then you can insert your card into tf slot, and mount it into `/mnt` directory.

For example, if you have an application called `coremark`, then you can directly run it using `/mnt/coremark`.

## Penglai Enclave Instructions

The monitor (OpenSBI) and Linux in this branch will initialize the Penglai related environment by default.

To ensure the Penglai Enclave is properly initialized, you can type:

~~~sh
ls /dev/penglai_enclave_dev
~~~

in your booted shell, and you should see the device.

### Run simple demo

The Penglai User SDK and demos are located in penglai-sdk/.

Currently it's still standalone and will not be compiled automatically.

Following the instructions to build the prime enclave demo and put it into the image:


**Build the demo**:

~~~sh
# In the root dir of the project
cd penglai-sdk
make
~~~


**Put the demo into the image**:

~~~sh
# In the root dir of the project
make preboot
cp penglai-sdk/demo/host/host work/buildroot_initramfs_sysroot/root/
cp penglai-sdk/demo/prime/prime work/buildroot_initramfs_sysroot/root/
make bootimages
~~~

Now boot with the newly created image, e.g.,

~~~sh
# In the root dir of the project
make upload_freeloader
~~~

 the booted shell, you should see host and prime in /root/.

**Run demo**:

~~~sh
# In /root
./host prime
~~~

You should see results like

~~~sh
M mode: exit_enclave: retval of enclave is 2
~~~

which is the expected result of the demo.

### Other infos

To learn more about Penglai, please refer information in [Penglai github](https://github.com/penglai-enclave/penglai-enclave).

## Help

You can run `make help` for quick usage of this Nuclei Linux SDK.

## Notice

This repo is based on opensource repo https://github.com/sifive/freedom-u-sdk/tree/archive/buildroot

## Known issues

* For UX600, if you run simulation using xl_spike, it can run to login prompt, but when you login, it will
  show timeout issue, this is caused by xl_spike timer is not standard type, but the boot images for FPGA
  board can boot successfully and works well.

* For UX600FD, if you run simulation using xl_spike, it can only run to init process, then it will enter to
  kernel panic, but the generated boot images works for FPGA board.

* For some SDCard format, it might not be supported, please check your SDCard is SDHC format.

## Reference

* [Buildroot Manual](https://buildroot.org/downloads/manual/manual.html)
* [OpenSBI Manual](https://github.com/riscv/opensbi#documentation)
* [Uboot Manual](https://www.denx.de/wiki/U-Boot/Documentation)
* [Linux Manual](https://www.kernel.org/doc/html/latest/)

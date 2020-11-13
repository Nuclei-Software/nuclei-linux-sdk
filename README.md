# Nuclei Linux SDK

[![Build](https://github.com/Nuclei-Software/nuclei-linux-sdk/workflows/Build/badge.svg)](https://github.com/Nuclei-Software/nuclei-linux-sdk/actions)

This will download external prebuilt toolchain, and build linux kernel, device tree, ramdisk,
and opensbi with linux kernel payload for Nuclei xl-spike which can emulate Nuclei UX600 SoC.

It can also build linux kernel, rootfs ramdisk, opensbi and freeloader for Nuclei UX600
SoC FPGA bitstream running in Nuclei HummingBird FPGA Board.

> The rootfs used in this SDK is initramfs format.

> * If you want to boot linux directly from flash without SD Card, please checkout
>   `dev_nuclei_flash` branch. You can switch to `dev_nuclei_flash` branch via command below:
>   ~~~
>   # Please make sure your workspace is clean
>   git status
>   # Fetch latest change, and checkout dev_nuclei_flash branch, and update submodules
>   git fetch -a
>   git checkout dev_nuclei_flash
>   git submodule init
>   git submodule update
>   # make sure the workspace is clean and your are on branch dev_nuclei_flash now 
>   git status
>   ~~~
> * The documentation in `dev_nuclei_flash` branch is also updated according to its feature.

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

* Checkout this repository using `git`.
  
  - If you have good network access to github, you can clone this repo using command
    `git clone https://github.com/Nuclei-Software/nuclei-linux-sdk`
  - Otherwise, you can try with our mirror maintained in gitee using command
    `git clone https://gitee.com/Nuclei-Software/nuclei-linux-sdk`     

* Then you will need to checkout all of the linked submodules using:

  ~~~shell
  cd nuclei-linux-sdk
  git submodule update --recursive --init
  ~~~

* To make sure you have checked out clean source code, you need to run `git status` command,
  and get expected output as below:

  ~~~
  On branch dev_nuclei
  Your branch is up to date with 'origin/dev_nuclei'.

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

Assume currently you are in `dev_nuclei` branch, and the working tree is clean.

Then you run the following command to update this repo:

~~~shell
# Pull lastest source code and rebase your local commits onto it
git pull --rebase origin dev_nuclei
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
call xl_spike_t construct function
warning: tohost and fromhost symbols not in ELF; can't communicate with target
UART: 
UART: OpenSBI v0.7-81-g4378320
UART:    ____                    _____ ____ _____
UART:   / __ \                  / ____|  _ \_   _|
UART:  | |  | |_ __   ___ _ __ | (___ | |_) || |
UART:  | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
UART:  | |__| | |_) |  __/ | | |____) | |_) || |_
UART:   \____/| .__/ \___|_| |_|_____/|____/_____|
UART:         | |
UART:         |_|
UART: 
UART: Platform Name       : Nuclei UX600
UART: Platform Features   : timer,mfdeleg
UART: Platform HART Count : 1
UART: Boot HART ID        : 0
UART: Boot HART ISA       : rv64imacsu
UART: BOOT HART Features  : pmp,scounteren,mcounteren,time
UART: BOOT HART PMP Count : 16
UART: Firmware Base       : 0xa0000000
UART: Firmware Size       : 76 KB
UART: Runtime SBI Version : 0.2
UART: 
UART: MIDELEG : 0x0000000000000222
UART: MEDELEG : 0x000000000000b109
UART: PMP0    : 0x00000000a0000000-0x00000000a001ffff (A)
UART: PMP1    : 0x0000000000000000-0x01ffffffffffffff (A,R,W,X)
UART: [    0.000000] OF: fdt: Ignoring memory range 0xa0000000 - 0xa0200000
UART: [    0.000000] Linux version 5.7.0-13090-gad29b1fc8e7b (hqfang@softserver) (riscv-nuclei-linux-gnu-gcc (GCC) 9.2.0, GNU ld (GNU Binutils) 2.32) #2 Fri Nov 13 08:26:51 CST 2020
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
UART: [    0.000000] Memory: 175380K/260096K available (2367K kernel code, 3952K rwdata, 2048K rodata, 4828K init, 256K bss, 84716K reserved, 0K cma-reserved)
UART: [    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
UART: [    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
UART: [    0.000000] plic: interrupt-controller@8000000: mapped 53 interrupts with 1 handlers for 2 contexts.
UART: [    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
UART: [    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
UART: [    0.004882] sched_clock: 64 bits at 32kHz, resolution 30517ns, wraps every 70368744171142ns
UART: [    2.232910] printk: console [hvc0] enabled
UART: [    2.299499] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
UART: [    2.419158] pid_max: default: 32768 minimum: 301
UART: [    2.592407] Mount-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
UART: [    2.685089] Mountpoint-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
UART: [    3.433776] devtmpfs: initialized
UART: [    4.037109] random: get_random_bytes called from 0xffffffe0007986f6 with crng_init=0
UART: [    4.199005] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
UART: [    4.319458] futex hash table entries: 256 (order: 0, 6144 bytes, linear)
UART: [    4.566192] NET: Registered protocol family 16
UART: [    7.578186] clocksource: Switched to clocksource riscv_clocksource
UART: [    8.311279] NET: Registered protocol family 2
UART: [    8.969116] tcp_listen_portaddr_hash hash table entries: 256 (order: 0, 4096 bytes, linear)
UART: [    9.097991] TCP established hash table entries: 2048 (order: 2, 16384 bytes, linear)
UART: [    9.263671] TCP bind hash table entries: 2048 (order: 2, 16384 bytes, linear)
UART: [    9.404418] TCP: Hash tables configured (established 2048 bind 2048)
UART: [    9.538055] UDP hash table entries: 256 (order: 1, 8192 bytes, linear)
UART: [    9.647613] UDP-Lite hash table entries: 256 (order: 1, 8192 bytes, linear)
UART: [    9.863586] NET: Registered protocol family 1
UART: [   10.131774] RPC: Registered named UNIX socket transport module.
UART: [   10.214752] RPC: Registered udp transport module.
UART: [   10.282531] RPC: Registered tcp transport module.
UART: [   10.349243] RPC: Registered tcp NFSv4.1 backchannel transport module.
UART: [   36.886138] workingset: timestamp_bits=62 max_order=16 bucket_order=0
UART: [   42.545227] io scheduler mq-deadline registered
UART: [   42.612731] io scheduler kyber registered
UART: [   74.874664] brd: module loaded
UART: [   78.885070] loop: module loaded
UART: [   79.486114] NET: Registered protocol family 17
UART: [   82.232482] Freeing unused kernel memory: 4828K
UART: [   82.325958] Run /init as init process
UART: Starting syslogd: OK
UART: Starting klogd: OK
UART: Running sysctl: OK
UART: Starting mdev... OK
UART: modprobe: can't change directory to '/lib/modules': No such file or directory
UART: Saving random seed: [  569.876708] random: dd: uninitialized urandom read (512 bytes read)
UART: OK
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

If you want to remove the login, and directly enter to bash, please check [**Known issues**](#known-issues).

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

You can also use `riscv-nuclei-elf-gdb` and `openocd` to download this program by yourself.

### Build SDCard Boot Images

If you have run `make sim` command before, please make sure you run `make preboot` to prepare
build environment for generate boot images.

If the freeloader is flashed to the board, then you can prepare the SDCard boot materials,
you can run `make bootimages` to generate the boot images to *work/boot*, and an zip file
called *work/boot.zip* , you can extract this *boot.zip* to your SDCard or copy all the files
located in *work/boot/*, make sure the files need to be put right in the root of SDCard,
then you can insert this SDCard to your SDCard slot(J57) beside the TFT LCD.

The contents of *work/boot* or *work/boot.zip* are as below:

* **kernel.dtb**  : device tree binary file
* **boot.scr**    : boot script used by uboot, generated from [./conf/uboot.cmd](conf/uboot.cmd)
* **uImage.lz4**  : lz4 archived kernel image
* **uInitrd.lz4** : lz4 archived rootfs image

> SDCard is recommended to use SDHC format.
> SDCard need to be formatted to `FAT32` format, with only 1 partition.

### Run Linux

When all above is done, you can reset the power on board, then opensbi will boot uboot, and
uboot will automatically load linux image and initramfs from SDCard and boot linux if everything
is prepared correctly.

If you met with issues, please check the [**Known issues**](#known-issues).

The linux login user name and password is *root* and *nuclei*.

Sample output in **UART @ 57600bps, Data 8bit, Parity None, Stop Bits 1bit, No Flow Control**.

~~~
OpenSBI v0.7-81-g4378320
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


U-Boot 2020.07-rc2-g89856aea41 (Nov 12 2020 - 16:47:47 +0800)

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
345 bytes read in 183 ms (1000 Bytes/s)
## Executing script at a8100000
Loading kernel
2342307 bytes read in 47356 ms (47.9 KiB/s)
Loading ramdisk
3050290 bytes read in 66327 ms (43.9 KiB/s)
Loading dtb
2594 bytes read in 246 ms (9.8 KiB/s)
Starts booting from SD
## Booting kernel from Legacy Image at a1000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    2342243 Bytes = 2.2 MiB
   Load Address: a0200000
   Entry Point:  a0200000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at a8300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    3050226 Bytes = 2.9 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at a8000000
   Booting using the fdt blob at 0xa8000000
   Uncompressing Kernel Image
   Using Device Tree in place at 00000000a8000000, end 00000000a8003a21

Starting kernel ...

[    0.000000] OF: fdt: Ignoring memory range 0xa0000000 - 0xa0200000
[    0.000000] Linux version 5.7.0-13090-gad29b1fc8e7b (hqfang@softserver) (riscv-nuclei-linux-gnu-gcc (GCC) 9.2.0, GNUld (GNU Binutils) 2.32) #1 Thu Nov 12 16:48:53 CST 2020
[    0.000000] Initial ramdisk at: 0x(____ptrval____) (3050226 bytes)
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
[    0.000000] Memory: 176484K/260096K available (2367K kernel code, 3952K rwdata, 2048K rodata, 120K init, 256K bss, 8612K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
[    0.000000] plic: interrupt-controller@8000000: mapped 53 interrupts with 1 handlers for 2 contexts.
[    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 11284357139654 ns
[    0.000823] sched_clock: 64 bits at 32kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.396606] printk: console [hvc0] enabled
[    0.408233] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.430267] pid_max: default: 32768 minimum: 301
[    0.457611] Mount-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.474884] Mountpoint-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.656402] devtmpfs: initialized
[    0.787231] random: get_random_bytes called from 0xffffffe0003986f6 with crng_init=0
[    0.817260] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.839416] futex hash table entries: 256 (order: 0, 6144 bytes, linear)
[    0.890563] NET: Registered protocol family 16
[    1.561798] clocksource: Switched to clocksource riscv_clocksource
[    1.713897] NET: Registered protocol family 2
[    1.800231] tcp_listen_portaddr_hash hash table entries: 256 (order: 0, 4096 bytes, linear)
[    1.821807] TCP established hash table entries: 2048 (order: 2, 16384 bytes, linear)
[    1.846954] TCP bind hash table entries: 2048 (order: 2, 16384 bytes, linear)
[    1.868469] TCP: Hash tables configured (established 2048 bind 2048)
[    1.907226] UDP hash table entries: 256 (order: 1, 8192 bytes, linear)
[    1.926025] UDP-Lite hash table entries: 256 (order: 1, 8192 bytes, linear)
[    1.965087] NET: Registered protocol family 1
[    2.033599] RPC: Registered named UNIX socket transport module.
[    2.047149] RPC: Registered udp transport module.
[    2.057891] RPC: Registered tcp transport module.
[    2.068634] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    2.114135] Trying to unpack rootfs image as initramfs...
[   18.149230] Freeing initrd memory: 2972K
[   18.216583] workingset: timestamp_bits=62 max_order=16 bucket_order=0
[   18.951324] io scheduler mq-deadline registered
[   18.963897] io scheduler kyber registered
[   26.308074] brd: module loaded
[   27.339141] loop: module loaded
[   27.376373] sifive_spi 10014000.spi: mapped; irq=1, cs=1
[   27.456451] sifive_spi 10034000.spi: mapped; irq=2, cs=1
[   27.604431] mmc_spi spi1.0: SD/MMC host mmc0, no DMA, no WP, no poweroff
[   27.665435] NET: Registered protocol family 17
[   27.810760] Freeing unused kernel memory: 120K
[   27.896179] mmc0: host does not support reading read-only switch, assuming write-enable
[   27.915374] mmc0: new SDHC card on SPI
[   27.954162] Run /init as init process
[   28.095581] mmcblk0: mmc0:0000 SA08G 7.21 GiB
[   28.690429]  mmcblk0: p1
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory
Saving random seed: [  146.098083] random: dd: uninitialized urandom read (512 bytes read)
OK

Welcome to Nuclei System Techology
nucleisys login: root
Password:
# cat /proc/cpuinfo
processor       : 0
hart            : 0
isa             : rv64imac
mmu             : sv39

# uname -a
Linux nucleisys 5.7.0-13090-gad29b1fc8e7b #1 Thu Nov 12 16:48:53 CST 2020 riscv64 GNU/Linux
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

## Help

You can run `make help` for quick usage of this Nuclei Linux SDK.

## Notice

This repo is based on opensource repo https://github.com/sifive/freedom-u-sdk/tree/archive/buildroot

## Known issues

* For UX600, if you run simulation using xl_spike, it can run to login prompt, but when you login, it will
  show timeout issue, this is caused by xl_spike timer is not standard type, but the boot images for FPGA
  board can boot successfully and works well.

  If you want to execute using `xl_spike` without the login, you can edit the *work/buildroot_initramfs_sysroot/etc/inittab* file(started from `# now run any rc scripts`) as below, and save it:

  ~~~
  # now run any rc scripts
  #::sysinit:/etc/init.d/rcS

  # Put a getty on the serial port
  #console::respawn:/sbin/getty -L  console 0 vt100 # GENERIC_SERIAL
  ::respawn:-/bin/sh
  ~~~

  And then type `make presim` and `make sim` to run linux in *xl_spike*, you will be able to get following output in final:

  ~~~
  ## a lot of boot message are reduced here ##
  UART: [  246.974853] sdhci: Secure Digital Host Controller Interface driver
  UART: [  247.057922] sdhci: Copyright(c) Pierre Ossman
  UART: [  247.447723] NET: Registered protocol family 17
  UART: [  266.205169] Freeing unused kernel memory: 36052K
  UART: [  266.314117] Run /init as init process
  UART: # ls
  ls
  UART: bin      init     linuxrc  opt      run      tmp
  UART: dev      lib      media    proc     sbin     usr
  UART: etc      lib64    mnt      root     sys      var
  UART: # cat /proc/cpuinfo
  cat /proc/cpuinfo
  UART: processor	: 0
  UART: hart		: 0
  UART: isa		: rv64imac
  UART: mmu		: sv39
  UART: 
  ~~~

* For UX600FD, if you run simulation using xl_spike, it can only run to init process, then it will enter to
  kernel panic, but the generated boot images works for FPGA board.

* For some SDCard format, it might not be supported, please check your SDCard is SDHC format.

* If you can't boot with the sdcard boot images, you can run the following commands in uboot to check whether sdcard is recognized.

  1. Type `mmcinfo` to check whether sdcard is recognized? If no output, please re-insert the sdcard, and try
     this command again, if still not working, please confirm that the MCS is correct or not?

     ~~~
     U-Boot 2020.07-rc2-g89856aea41 (Aug 05 2020 - 21:18:04 +0800)

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
     => mmcinfo
     Device: spi@10034000:mmc@0
     Manufacturer ID: 2
     OEM: 544d
     Name: SA08G
     Bus Speed: 20000000
     Mode: MMC legacy
     Rd Block Len: 512
     SD version 2.0
     High Capacity: Yes
     Capacity: 7.2 GiB
     Bus Width: 1-bit
     Erase Group Size: 512 Bytes
     ~~~
   
  2. If SDCard is recognized correctly, please type `fatls mmc 0`, and check whether the following files
     are listed as below, if you can get the following files in your sdcard, please reformat your sdcard to `Fat32` format, and copy the generated files in *work/boot/* to the root of sdcard, and re-insert the
     sdcard to SD slot, and retry from step 1.

     **Note:** Please make sure your SDCard is safely injected in your OS, and SDCard is formated to `Fat32`.

     ~~~
     => fatls mmc 0
         2594   kernel.dtb   # device tree binary file
          345   boot.scr     # boot script used by uboot, generated from ./conf/uboot.cmd
      3052821   uImage.lz4   # lz4 archived kernel image
      19155960  uInitrd.lz4  # lz4 archived rootfs image

      4 file(s), 0 dir(s)
     ~~~

  3. If the above steps are all correct, then you can run `boot` command to boot linux, or type commands
     located in [./conf/uboot.cmd](conf/uboot.cmd).

* The linux kernel and rootfs size is too big, is there any way to reduce it to speed up boot speed?

  If you are familiar with linux and buildroot configuration files, you can directly modify the configuration
  files located in `conf` folder.

  * *conf/buildroot_initramfs_ux600_config*: The buildroot configuration for UX600
  * *conf/buildroot_initramfs_ux600fd_config*: The buildroot configuration for UX600FD
  * *conf/linux_defconfig*: The linux configuration for UX600 and UX600FD
  * *conf/nuclei_ux600.dts*: The device tree file for UX600
  * *conf/nuclei_ux600fd.dts*: The device tree file for UX600FD

  If you modified this files directly and want to take effects, you need to `make clean` first, and regenerate
  boot images.

  You can also try `make buildroot_initramfs-menuconfig` to get a terminal menuconfig to configure the buildroot
  packages.

  You can also try `make linux-menuconfig` to get a  menuconfig to configure the linux kernel.

* Other possible ways to reduce generated rootfs image size.

  If you are familiar with the generated rootfs files located in `work/buildroot_initramfs_sysroot`, you can
  manually remove the files you think it is not used, and type `make cleanboot` and then `make bootimages`,
  you can check the size information generated by the command.

* The best way to learn this project is taking a look at the [Makefile](Makefile) of this project to learn about
  what is really done in each make target.

* Download *freeloader/freeloader.elf* using Nuclei SDK.

  If you don't want to build the nuclei sdk, you can also download the boot images generated by [github action](https://github.com/Nuclei-Software/nuclei-linux-sdk/actions).

  For example, for `dev_nuclei` branch, you can find the previous built artifacts in https://github.com/Nuclei-Software/nuclei-linux-sdk/actions/runs/358740696.

  Then you can extra the downloaded `bootimages_ux600.zip` and extract `freeloader/freeloader.elf` to your disk,
  such as `D:/freeloader.elf`.

  Make sure you have followed [steps](https://doc.nucleisys.com/nuclei_sdk/quickstart.html) to setup nuclei sdk
  development environment, then you can follow steps below to download this `D:/freeloader.elf`.

  ~~~
  D:\workspace\Sourcecode\nuclei-sdk>setup.bat
  Setup Nuclei SDK Tool Environment
  NUCLEI_TOOL_ROOT=D:\Software\NucleiStudio_IDE_202009\NucleiStudio\toolchain
  
  D:\workspace\Sourcecode\nuclei-sdk>make clean
  make -C application/baremetal/helloworld clean
  make[1]: Entering directory 'D:/workspace/Sourcecode/nuclei-sdk/application/baremetal/helloworld'
  "Clean all build objects"
  make[1]: Leaving directory 'D:/workspace/Sourcecode/nuclei-sdk/application/baremetal/helloworld'
  
  D:\workspace\Sourcecode\nuclei-sdk>make CORE=ux600 debug
  make -C application/baremetal/helloworld debug
  make[1]: Entering directory 'D:/workspace/Sourcecode/nuclei-sdk/application/baremetal/helloworld'
  .... ....
  "Compiling  : " ../../../SoC/hbird/Common/Source/system_hbird.c
  "Compiling  : " main.c
  "Linking    : " helloworld.elf
     text    data     bss     dec     hex filename
     8328     224    2492   11044    2b24 helloworld.elf
  "Download and debug helloworld.elf"
  riscv-nuclei-elf-gdb helloworld.elf -ex "set remotetimeout 240" \
          -ex "target remote | openocd --pipe -f ../../../SoC/hbird/Board/hbird_eval/openocd_hbird.cfg"
  D:\Software\NucleiStudio_IDE_202009\NucleiStudio\toolchain\gcc\bin\riscv-nuclei-elf-gdb.exe: warning: Couldn't     determine a path for the index cache directory.
  GNU gdb (GDB) 8.3.0.20190516-git
  Copyright (C) 2019 Free Software Foundation, Inc.
  License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
  This is free software: you are free to change and redistribute it.
  There is NO WARRANTY, to the extent permitted by law.
  Type "show copying" and "show warranty" for details.
  This GDB was configured as "--host=i686-w64-mingw32 --target=riscv-nuclei-elf".
  Type "show configuration" for configuration details.
  For bug reporting instructions, please see:
  <http://www.gnu.org/software/gdb/bugs/>.
  Find the GDB manual and other documentation resources online at:
      <http://www.gnu.org/software/gdb/documentation/>.
  
  For help, type "help".
  Type "apropos word" to search for commands related to "word"...
  Reading symbols from helloworld.elf...
  Remote debugging using | openocd --pipe -f ../../../SoC/hbird/Board/hbird_eval/openocd_hbird.cfg
  Nuclei OpenOCD, 64-bit Open On-Chip Debugger 0.10.0+dev-00020-g7701266e6-dirty (2020-09-22-07:31)
  Licensed under GNU GPL v2
  For bug reports, read
          http://openocd.org/doc/doxygen/bugs.html
  --Type <RET> for more, q to quit, c to continue without paging--
  0x00000000a0005aea in ?? ()
  (gdb) monitor reset halt
  JTAG tap: riscv.cpu tap/device found: 0x12050a6d (mfg: 0x536 (Nuclei System Technology Co.,Ltd.), part: 0x2050,     ver: 0x1)
  (gdb) load D:/freeloader.elf
  Loading section .text, size 0x831e0 lma 0x20000000
  Loading section .interp, size 0x20 lma 0x200831e0
  Loading section .dynsym, size 0x18 lma 0x20083200
  Loading section .dynstr, size 0xb lma 0x20083218
  Loading section .hash, size 0x10 lma 0x20083228
  Loading section .gnu.hash, size 0x1c lma 0x20083238
  Loading section .dynamic, size 0x110 lma 0x20083258
  Loading section .got, size 0x8 lma 0x20083368
  Start address 0x20000000, load size 537447
  Transfer rate: 22 KB/sec, 13108 bytes/write.
  (gdb) q
  A debugging session is active.
  
          Inferior 1 [Remote target] will be detached.
  
  Quit anyway? (y or n) y
  Detaching from program: D:\workspace\Sourcecode\nuclei-sdk\application\baremetal\helloworld\helloworld.elf, Remote     target
  Ending remote debugging.
  [Inferior 1 (Remote target) detached]
  make[1]: Leaving directory 'D:/workspace/Sourcecode/nuclei-sdk/application/baremetal/helloworld'
  ~~~


## Reference

* [Buildroot Manual](https://buildroot.org/downloads/manual/manual.html)
* [OpenSBI Manual](https://github.com/riscv/opensbi#documentation)
* [Uboot Manual](https://www.denx.de/wiki/U-Boot/Documentation)
* [Linux Manual](https://www.kernel.org/doc/html/latest/)

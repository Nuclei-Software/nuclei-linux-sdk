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
- Build dependencies: `build-essential git autotools texinfo bison flex lz4
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

## Toolchain Setup

Choose the external or internal toolchain you would like to use, and better not
to change it in future, otherwise, you need to run `make clean` before you switch
toolchain.

### Build using external toolchain

If you want to build using prebuilt external toolchain provided by Nuclei,
you can run `export EXTERNAL_TOOLCHAIN=1` before do any make steps.

When `EXTERNAL_TOOLCHAIN=1` then buildroot configuration file in
*conf/buildroot_ext_tool_initramfs_config* will be used.

### Build with internal buildroot toolchain

If you want to build using internal toolchain built by buildroot,
you can run `export EXTERNAL_TOOLCHAIN=0` before do any make steps.

When `EXTERNAL_TOOLCHAIN=0` then buildroot configuration file in
*conf/buildroot_initramfs_config* will be used.

## Booting Linux on Nuclei xl-spike

**Note**: `xl_spike` tool should be installed and added into **PATH** in advance.
Contact with our sales via email contact@nucleisys.com to get `xl-spike` tools.

### Run on xl_spike 

If you have run `make bootimages` command before, please make sure you run `make presim` to prepare
build environment for running linux in simulation.

When toolchain steps are finished, then, you can build buildroot, linux and opensbi,
and run opensbi with linux payload on xlspike by running `make sim`.

Here is sample output running in xl_spike:

~~~console
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
UART: Boot HART ISA          : rv64imacsu
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
UART: [    0.000000] Linux version 5.7.0-rc6-00001-g9e40580a2b69 (hqfang@softserver) (gcc version 9.2.0 (GCC), GNU ld (GNU Binutils) 2.32) #4 Thu May 21 16:12:06 CST 2020
UART: [    0.000000] initrd not found or empty - disabling initrd
UART: [    0.000000] Zone ranges:
UART: [    0.000000]   DMA32    [mem 0x00000000a0200000-0x00000000afffffff]
UART: [    0.000000]   Normal   empty
UART: [    0.000000] Movable zone start for each node
UART: [    0.000000] Early memory node ranges
UART: [    0.000000]   node   0: [mem 0x00000000a0200000-0x00000000afffffff]
UART: [    0.000000] Initmem setup node 0 [mem 0x00000000a0200000-0x00000000afffffff]
UART: [    0.000000] software IO TLB: mapped [mem 0xabc7d000-0xafc7d000] (64MB)
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
UART: [    0.000000] Memory: 144648K/260096K available (2676K kernel code, 3654K rwdata, 2048K rodata, 35856K init, 261K bss, 115448K reserved, 0K cma-reserved)
UART: [    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
UART: [    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
UART: [    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
UART: [    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
UART: [    0.004852] sched_clock: 64 bits at 32kHz, resolution 30517ns, wraps every 70368744171142ns
UART: [    2.120269] printk: console [hvc0] enabled
UART: [    2.186859] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
UART: [    2.306457] pid_max: default: 32768 minimum: 301
UART: [    2.482086] Mount-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
UART: [    2.574737] Mountpoint-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
UART: [    3.349182] devtmpfs: initialized
UART: [    3.919036] random: get_random_bytes called from setup_net+0x38/0x180 with crng_init=0
UART: [    4.087646] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
UART: [    4.204467] futex hash table entries: 256 (order: 0, 6144 bytes, linear)
UART: [    4.453796] NET: Registered protocol family 16
UART: [    7.855560] clocksource: Switched to clocksource riscv_clocksource
UART: [    8.604278] NET: Registered protocol family 2
UART: [    9.261505] tcp_listen_portaddr_hash hash table entries: 256 (order: 0, 4096 bytes, linear)
UART: [    9.386444] TCP established hash table entries: 2048 (order: 2, 16384 bytes, linear)
UART: [    9.551971] TCP bind hash table entries: 2048 (order: 2, 16384 bytes, linear)
UART: [    9.692352] TCP: Hash tables configured (established 2048 bind 2048)
UART: [    9.831176] UDP hash table entries: 256 (order: 1, 8192 bytes, linear)
UART: [    9.936676] UDP-Lite hash table entries: 256 (order: 1, 8192 bytes, linear)
UART: [   10.151519] NET: Registered protocol family 1
UART: [   10.429138] RPC: Registered named UNIX socket transport module.
UART: [   10.512054] RPC: Registered udp transport module.
UART: [   10.579681] RPC: Registered tcp transport module.
UART: [   10.646270] RPC: Registered tcp NFSv4.1 backchannel transport module.
UART: [  192.773651] workingset: timestamp_bits=62 max_order=16 bucket_order=0
UART: [  202.740844] io scheduler mq-deadline registered
UART: [  202.805267] io scheduler kyber registered
UART: [  235.080230] brd: module loaded
UART: [  239.100372] loop: module loaded
UART: [  239.354187] sdhci: Secure Digital Host Controller Interface driver
UART: [  239.440673] sdhci: Copyright(c) Pierre Ossman
UART: [  239.809204] NET: Registered protocol family 17
UART: [  258.251251] Freeing unused kernel memory: 35856K
UART: [  258.353332] Run /init as init process
UART: Starting syslogd: OK
UART: Starting klogd: OK
UART: Running sysctl: OK
UART: Starting mdev... OK
~~~

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

If you have run `make sim` command before, please make sure you run `make preboot` to prepare
build environment for generate boot images.

If the freeloader is flashed to the board, then you can prepare the SDCard boot materials,
you can run `make bootimages` to generate the boot images to *work/boot*, and an zip file
called *work/boot.zip* , you can copy this *boot.zip* file to your SDCard, and extract it,
then you can insert this SDCard to your SDCard slot beside the TFT LCD.

### Run Linux

When all above is done, you can reset the power on board, then opensbi will boot uboot, and
uboot will automatically load linux image and initramfs from SDCard and boot linux.

The linux login user name and password is *root* and *nuclei*.

Sample output in UART @ 57600bps.

~~~console
OpenSBI v0.7
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : Nuclei UX600
Platform HART Count    : 1
Platform Features      : timer,mfdeleg
Boot HART ID           : 0
Boot HART ISA          : rv64imacsu
BOOT HART Features     : pmp,scountern,mcounteren,time
Firmware Base          : 0xa0000000
Firmware Size          : 76 KB
Runtime SBI Version    : 0.2

MIDELEG : 0x0000000000000222
MEDELEG : 0x000000000000b109
PMP0    : 0x00000000a0000000-0x00000000a001ffff (A)
PMP1    : 0x0000000000000000-0x0000007fffffffff (A,R,W,X)


U-Boot 2020.07-rc2-ga7de5fe980 (May 20 2020 - 14:46:19 +0800)

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
290 bytes read in 26 ms (10.7 KiB/s)
## Executing script at a8100000
Loading kernel
2945733 bytes read in 7405 ms (387.7 KiB/s)
Loading ramdisk
19325270 bytes read in 48492 ms (388.7 KiB/s)
Starts booting from SD
## Booting kernel from Legacy Image at a1000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    2945669 Bytes = 2.8 MiB
   Load Address: a0200000
   Entry Point:  a0200000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at a8300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    19325206 Bytes = 18.4 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at a8000000
   Booting using the fdt blob at 0xa8000000
   Uncompressing Kernel Image
   Using Device Tree in place at 00000000a8000000, end 00000000a8004a51

Starting kernel ...

[    0.000000] OF: fdt: Ignoring memory range 0xa0000000 - 0xa0200000
[    0.000000] Linux version 5.7.0-rc6-00001-g9e40580a2b69 (hqfang@softserver) (gcc version 9.2.0 (GCC), GNU ld (GNU Binutils) 2.32) #1 Thu May 21 15:31:19 CST 2020
[    0.000000] Initial ramdisk at: 0x(____ptrval____) (19325206 bytes)
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
[    0.000000] Memory: 160580K/260096K available (2676K kernel code, 3654K rwdata, 2048K rodata, 120K init, 261K bss, 99516K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
[    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000183] sched_clock: 64 bits at 32kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.371215] printk: console [hvc0] enabled
[    0.379882] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.399841] pid_max: default: 32768 minimum: 301
[    0.413146] Mount-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.427246] Mountpoint-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.479034] devtmpfs: initialized
[    0.510589] random: get_random_bytes called from setup_net+0x38/0x180 with crng_init=0
[    0.514190] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.549316] futex hash table entries: 256 (order: 0, 6144 bytes, linear)
[    0.570861] NET: Registered protocol family 16
[    0.715393] clocksource: Switched to clocksource riscv_clocksource
[    0.759735] NET: Registered protocol family 2
[    0.783721] tcp_listen_portaddr_hash hash table entries: 256 (order: 0, 4096 bytes, linear)
[    0.800506] TCP established hash table entries: 2048 (order: 2, 16384 bytes, linear)
[    0.816864] TCP bind hash table entries: 2048 (order: 2, 16384 bytes, linear)
[    0.831787] TCP: Hash tables configured (established 2048 bind 2048)
[    0.849426] UDP hash table entries: 256 (order: 1, 8192 bytes, linear)
[    0.862670] UDP-Lite hash table entries: 256 (order: 1, 8192 bytes, linear)
[    0.880584] NET: Registered protocol family 1
[    0.900421] RPC: Registered named UNIX socket transport module.
[    0.911682] RPC: Registered udp transport module.
[    0.921081] RPC: Registered tcp transport module.
[    0.930633] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    0.950134] Trying to unpack rootfs image as initramfs...
[   28.934753] Freeing initrd memory: 18868K
[   28.954437] workingset: timestamp_bits=62 max_order=16 bucket_order=0
[   29.232269] io scheduler mq-deadline registered
[   29.240753] io scheduler kyber registered
[   30.807312] brd: module loaded
[   31.038543] loop: module loaded
[   31.048370] nuclei_spi 10014000.spi: IRQ index 0 not found
[   31.060272] nuclei_spi 10034000.spi: IRQ index 0 not found
[   31.076843] sdhci: Secure Digital Host Controller Interface driver
[   31.088409] sdhci: Copyright(c) Pierre Ossman
[   31.106018] NET: Registered protocol family 17
[   31.135894] Freeing unused kernel memory: 120K
[   31.145019] Run /init as init process
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory
Saving random seed: [   55.008789] random: dd: uninitialized urandom read (512 bytes read)
OK

Welcome to Nuclei System Techology
nucleisys login: root
Password:
# uname -a
Linux nucleisys 5.7.0-rc6-00001-g9e40580a2b69 #1 Thu May 21 15:31:19 CST 2020 riscv64 GNU/Linux
# cat /proc/cpuinfo
processor       : 0
hart            : 0
isa             : rv64imac
mmu             : sv39

# ls /
bin      init     linuxrc  opt      run      tmp
dev      lib      media    proc     sbin     usr
etc      lib64    mnt      root     sys      var
~~~

## Help

You can run `make help` for quick usage of this Nuclei Linux SDK.

## Notice

This repo is based on opensource repo https://github.com/sifive/freedom-u-sdk/tree/archive/buildroot

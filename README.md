# Nuclei Linux SDK

This will download external prebuilt toolchain, and build linux kernel, device tree, ramdisk,
and opensbi with linux kernel payload for Nuclei xl-spike which can emulate Nuclei UX600 SoC.

It can also build linux kernel, ramdisk, opensbi and freeloader for Nuclei UX600
SoC FPGA bitstream running in Nuclei HummingBird FPGA Board.

## Tested Configurations

### Ubuntu 18.04 x86_64 host

- Status: Working
- Build dependencies: `build-essential git autotools texinfo bison flex lz4
  libgmp-dev libmpfr-dev libmpc-dev gawk libz-dev libssl-dev device-tree-compiler`
- Get prebuilt openocd from [Nuclei Development Tools](https://nucleisys.com/download.php)
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

## Select UX600 Core Configuration

You can choose different core configuration by modify the `CORE ?= ux600` line in Makefile.

We support two configurations for **CORE**:

* `ux600`: rv64imac core configuration without FPU.
* `ux600fd`: rv64imafdc core configuration with FPU.

Please modify to your correct core configuration before build any source code.

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

Sample output in **UART @ 57600bps**.

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
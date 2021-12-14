# Nuclei Linux SDK

[![Build](https://github.com/Nuclei-Software/nuclei-linux-sdk/workflows/Build/badge.svg)](https://github.com/Nuclei-Software/nuclei-linux-sdk/actions)

> This branch is used to evaluate keystone enclave feature on Nuclei Evaluation SoC.

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
   libgmp-dev libmpfr-dev libmpc-dev gawk libz-dev libssl-dev device-tree-compiler libncursesw5-dev libncursesw5 makeself rsync cpio expect
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
  # this is important, since submodule may has submodule
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
# Update git submodules and submodule's submodule
git submodule update --init --recursive
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
xl_spike --isa=rv64gc /home/hqfang/workspace/software/nuclei-linux-sdk/work/opensbi/platform/nuclei/ux600/firmware/fw_payload.elf
rv64 file
call xl_spike_t construct function
warning: tohost and fromhost symbols not in ELF; can't communicate with target
UART: 
UART: OpenSBI v0.8
UART:    ____                    _____ ____ _____
UART:   / __ \                  / ____|  _ \_   _|
UART:  | |  | |_ __   ___ _ __ | (___ | |_) || |
UART:  | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
UART:  | |__| | |_) |  __/ | | |____) | |_) || |_
UART:   \____/| .__/ \___|_| |_|_____/|____/_____|
UART:         | |
UART:         |_|
UART: 
UART: Platform Name             : Nuclei UX600
UART: Platform Features         : timer,mfdeleg
UART: Platform HART Count       : 1
UART: Firmware Base             : 0xa0000000
UART: Firmware Size             : 184 KB
UART: Runtime SBI Version       : 0.2
UART: 
UART: Domain0 Name              : root
UART: Domain0 Boot HART         : 0
UART: Domain0 HARTs             : 0*
UART: Domain0 Region00          : 0x00000000a0000000-0x00000000a003ffff ()
UART: Domain0 Region01          : 0x0000000000000000-0xffffffffffffffff (R,W,X)
UART: Domain0 Next Address      : 0x00000000a0200000
UART: Domain0 Next Arg1         : 0x00000000a8000000
UART: Domain0 Next Mode         : S-mode
UART: Domain0 SysReset          : yes
UART: 
UART: pmp_set 0, 0x0, 0xa0000000, 18
UART: pmpaddr csr write 3b0: 0x28007fff
UART: pmpcfg csr write 3a0: 0x18
UART: pmp_set 1, 0x7, 0x0, 64
UART: pmpaddr csr write 3b1: 0xffffffffffffffff
UART: pmpcfg csr write 3a0: 0x1f18
UART: [SM] Initializing ... hart [0]
UART: [SM] Keystone security monitor has been initialized!
UART: Boot HART ID              : 0
UART: Boot HART Domain          : root
UART: Boot HART ISA             : rv64imafdcsu
UART: Boot HART Features        : scounteren,mcounteren,time
UART: Boot HART PMP Count       : 16
UART: Boot HART PMP Granularity : 4
UART: Boot HART PMP Address Bits: 54
UART: Boot HART MHPM Count      : 0
UART: Boot HART MHPM Count      : 0
UART: Boot HART MIDELEG         : 0x0000000000000222
UART: Boot HART MEDELEG         : 0x000000000000b109
UART: [    0.000000] OF: fdt: Ignoring memory block 0x10010000 - 0x10020000
UART: [    0.000000] OF: fdt: Ignoring memory range 0x70000000 - 0xa0200000
UART: [    0.000000] Linux version 5.7.0+ (hqfang@softserver) (riscv-nuclei-linux-gnu-gcc (GCC) 9.2.0, GNU ld (GNU Binutils) 2.32) #2 Tue Feb 2 18:32:25 CST 2021
UART: [    0.000000] initrd not found or empty - disabling initrd
UART: [    0.000000] Zone ranges:
UART: [    0.000000]   DMA32    [mem 0x00000000a0200000-0x00000000ffffffff]
UART: [    0.000000]   Normal   [mem 0x0000000100000000-0x00000002001fffff]
UART: [    0.000000] Movable zone start for each node
UART: [    0.000000] Early memory node ranges
UART: [    0.000000]   node   0: [mem 0x00000000a0200000-0x00000002001fffff]
UART: [    0.000000] Initmem setup node 0 [mem 0x00000000a0200000-0x00000002001fffff]
UART: [    0.000000] cma: Reserved 92 MiB at 0x00000001f5800000
UART: [    0.000000] software IO TLB: mapped [mem 0xfbfff000-0xfffff000] (64MB)
UART: [    0.000000] SBI specification v0.2 detected
UART: [    0.000000] SBI implementation ID=0x1 Version=0x8
UART: [    0.000000] SBI v0.2 TIME extension detected
UART: [    0.000000] SBI v0.2 IPI extension detected
UART: [    0.000000] SBI v0.2 RFENCE extension detected
UART: [    0.000000] riscv: ISA extensions acdfim
UART: [    0.000000] riscv: ELF capabilities acdfim
UART: [    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 1422080
UART: [    0.000000] Kernel command line: console=hvc0 earlycon=sbi
UART: [    0.000000] Dentry cache hash table entries: 1048576 (order: 11, 8388608 bytes, linear)
UART: [    0.000000] Inode-cache hash table entries: 524288 (order: 10, 4194304 bytes, linear)
UART: [    0.000000] Sorting __ex_table...
UART: [    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
UART: [    0.000000] Memory: 5498672K/5767168K available (2507K kernel code, 4115K rwdata, 2048K rodata, 8128K init, 239K bss, 174288K reserved, 94208K cma-reserved)
UART: [    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
UART: [    0.000000] ftrace: allocating 11660 entries in 46 pages
UART: [    0.000000] ftrace: allocated 46 pages with 4 groups
UART: [    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
UART: [    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
UART: [    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x24e6a1710, max_idle_ns: 440795202120 ns
UART: [    0.000016] sched_clock: 64 bits at 10MHz, resolution 100ns, wraps every 4398046511100ns
UART: [    0.008107] printk: console [hvc0] enabled
UART: [    0.008310] Calibrating delay loop (skipped), value calculated using timer frequency.. 20.00 BogoMIPS (lpj=100000)
UART: [    0.008732] pid_max: default: 32768 minimum: 301
UART: [    0.009309] Mount-cache hash table entries: 16384 (order: 5, 131072 bytes, linear)
UART: [    0.009715] Mountpoint-cache hash table entries: 16384 (order: 5, 131072 bytes, linear)
UART: [    0.012528] devtmpfs: initialized
UART: [    0.014040] random: get_random_bytes called from setup_net+0x46/0x19e with crng_init=0
UART: [    0.014339] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
UART: [    0.015041] futex hash table entries: 256 (order: 0, 6144 bytes, linear)
UART: [    0.019612] NET: Registered protocol family 16
UART: [    0.025477] clocksource: Switched to clocksource riscv_clocksource
UART: [    0.208155] workingset: timestamp_bits=62 max_order=21 bucket_order=0
UART: [    0.219808] io scheduler mq-deadline registered
UART: [    0.219995] io scheduler kyber registered
UART: [    0.301697] brd: module loaded
UART: [    0.311531] loop: module loaded
UART: [    1.814006] Freeing unused kernel memory: 8128K
UART: [    1.815130] Run /init as init process
UART: Starting syslogd: OK
UART: Starting klogd: OK
UART: Running sysctl: OK
UART: Starting mdev... OK
UART: modprobe: can't change directory to '/lib/modules': No such file or directory
UART: Saving random seed: [    3.239555] random: dd: uninitialized urandom read (512 bytes read)
UART: OK
UART: 
UART: Welcome to Nuclei System Techology
nucleisys login: root
root
UART: Password: nuclei

UART: login[152]: root login on 'console'
UART: # ls
ls
UART: keystone-driver.ko  tests.ke
UART: # insmod keystone-driver.ko
insmod keystone-driver.ko
UART: [    6.141497] keystone_driver: loading out-of-tree module taints kernel.
UART: [    6.143746] keystone_enclave: keystone enclave v1.0.0
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
Executing bootrom
Measure Secure Monitor
Combine SK_D and H_SM via a hash
Endorse the SM
Clean up
Finish

OpenSBI v0.8
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name             : Nuclei UX600
Platform Features         : timer,mfdeleg
Platform HART Count       : 1
Firmware Base             : 0xa0000000
Firmware Size             : 184 KB
Runtime SBI Version       : 0.2

Domain0 Name              : root
Domain0 Boot HART         : 0
Domain0 HARTs             : 0*
Domain0 Region00          : 0x00000000a0000000-0x00000000a003ffff ()
Domain0 Region01          : 0x0000000000000000-0xffffffffffffffff (R,W,X)
Domain0 Next Address      : 0x00000000a0400000
Domain0 Next Arg1         : 0x00000000a8000000
Domain0 Next Mode         : S-mode
Domain0 SysReset          : yes

pmp_set 0, 0x0, 0xa0000000, 18
pmpaddr csr write 3b0: 0x28007fff
pmpcfg csr write 3a0: 0x18
pmp_set 1, 0x7, 0x0, 64
pmpaddr csr write 3b1: 0xffffffffffffffff
pmpcfg csr write 3a0: 0x1f18
[SM] Initializing ... hart [0]
[SM] Keystone security monitor has been initialized!
Boot HART ID              : 0
Boot HART Domain          : root
Boot HART ISA             : rv64imafdcpsu
Boot HART Features        : scounteren,mcounteren,time
Boot HART PMP Count       : 16
Boot HART PMP Granularity : 4096
Boot HART PMP Address Bits: 30
Boot HART MHPM Count      : 0
Boot HART MHPM Count      : 0
Boot HART MIDELEG         : 0x0000000000000222
Boot HART MEDELEG         : 0x000000000000b109


U-Boot 2020.07-rc2-g9e4b5eec42 (Feb 01 2021 - 10:55:29 +0800)

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
345 bytes read in 37 ms (8.8 KiB/s)
## Executing script at a8100000
Loading kernel
2630298 bytes read in 8914 ms (288.1 KiB/s)
Loading ramdisk
5049891 bytes read in 17071 ms (288.1 KiB/s)
Loading dtb
2598 bytes read in 47 ms (53.7 KiB/s)
Starts booting from SD
## Booting kernel from Legacy Image at a1000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    2630234 Bytes = 2.5 MiB
   Load Address: a0200000
   Entry Point:  a0200000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at a8300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    5049827 Bytes = 4.8 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at a8000000
   Booting using the fdt blob at 0xa8000000
   Uncompressing Kernel Image
   Using Device Tree in place at 00000000a8000000, end 00000000a8003a25

Starting kernel ...

[    0.000000] OF: fdt: Ignoring memory range 0xa0000000 - 0xa0200000
[    0.000000] Linux version 5.7.0+ (hqfang@softserver) (riscv-nuclei-linux-gnu-gcc (GCC) 9.2.0, GNU ld (GNU Binutils) 2.32) #1 Mon Feb 1 11:17:31 CST 2021
[    0.000000] Initial ramdisk at: 0x(____ptrval____) (5049827 bytes)
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x00000000a0200000-0x00000000afffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x00000000a0200000-0x00000000afffffff]
[    0.000000] Initmem setup node 0 [mem 0x00000000a0200000-0x00000000afffffff]
[    0.000000] cma: Reserved 92 MiB at 0x00000000aa000000
[    0.000000] software IO TLB: mapped [mem 0xa4000000-0xa8000000] (64MB)
[    0.000000] SBI specification v0.2 detected
[    0.000000] SBI implementation ID=0x1 Version=0x8
[    0.000000] SBI v0.2 TIME extension detected
[    0.000000] SBI v0.2 IPI extension detected
[    0.000000] SBI v0.2 RFENCE extension detected
[    0.000000] riscv: ISA extensions acdfim
[    0.000000] riscv: ELF capabilities acdfim
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 64135
[    0.000000] Kernel command line: earlycon=sbi
[    0.000000] Dentry cache hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    0.000000] Inode-cache hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    0.000000] Sorting __ex_table...
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Memory: 80044K/260096K available (2507K kernel code, 4115K rwdata, 2048K rodata, 240K init, 239K bss, 85844K reserved, 94208K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] ftrace: allocating 11660 entries in 46 pages
[    0.000000] ftrace: allocated 46 pages with 4 groups
[    0.000000] NR_IRQS: 0, nr_irqs: 0, preallocated irqs: 0
[    0.000000] plic: interrupt-controller@8000000: mapped 53 interrupts with 1 handlers for 2 contexts.
[    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000305] sched_clock: 64 bits at 32kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.421508] printk: console [hvc0] enabled
[    0.429901] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.450073] pid_max: default: 32768 minimum: 301
[    0.467407] Mount-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.482269] Mountpoint-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.558624] devtmpfs: initialized
[    0.616058] random: get_random_bytes called from setup_net+0x46/0x19e with crng_init=0
[    0.640472] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.660369] futex hash table entries: 256 (order: 0, 6144 bytes, linear)
[    0.854339] NET: Registered protocol family 16
[    1.093475] clocksource: Switched to clocksource riscv_clocksource
[    3.330505] Trying to unpack rootfs image as initramfs...
[   12.713378] Freeing initrd memory: 4924K
[   12.741638] workingset: timestamp_bits=62 max_order=16 bucket_order=0
[   12.995117] io scheduler mq-deadline registered
[   13.004058] io scheduler kyber registered
[   15.811004] brd: module loaded
[   16.155517] loop: module loaded
[   16.173004] sifive_spi 10014000.spi: mapped; irq=1, cs=1
[   16.209869] sifive_spi 10034000.spi: mapped; irq=2, cs=1
[   34.085235] Freeing unused kernel memory: 240K
[   34.095977] Run /init as init process
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory
Saving random seed: [   84.431854] random: dd: uninitialized urandom read (512 bytes read)
OK

Welcome to Nuclei System Techology
nucleisys login: root
Password:
login[157]: root login on 'console'
# ls
keystone-driver.ko  tests.ke
# insmod keystone-driver.ko
[  114.766967] keystone_driver: loading out-of-tree module taints kernel.
[  114.866058] keystone_enclave: keystone enclave v1.0.0
# ./tests.ke --target tests --noexec
Creating directory tests
Verifying archive integrity... All good.
Uncompressing Keystone Enclave Packagedf: tests: can't find mount point
./tests.ke: line 526: test: Available: integer expression expected

# ls
keystone-driver.ko  tests               tests.ke
# cd tests
# ls
attestation   fib-bench     loop          stack
data-sealing  fibonacci     malloc        test-runner
eyrie-rt      long-nop      run-test.sh   untrusted
# ./run-test.sh
testing stack
[keystone-test]Start test runner
[keystone-test]Enclave init: eapp_file stack, rt_file eyrie-rt
[  166.246063] keystone_enclave: epm allocated 4096 page(s) @ 00000000aa000000, CMA=1
[  166.500915] keystone_enclave: utm allocated 512 page(s) @ ffffffe003a00000
[  167.718475] keystone_enclave: epm: addr 00000000aa000000, size 16777216; utm: addr 00000000a3c00000, size 2097152
create_enclave: check runtime param
[create args info]:
        epm_addr: aa000000
        epmsize: 1000000
        utm_addr: a3c00000
        utmsize: 200000
        runtime_addr: aa003000
        user_addr: aa01e000
        free_addr: aa027000
create_enclave: allocate eid
create_enclave: setup PMP regions
create_enclave: cleanup memory regions
create_enclave: Init enclave state
create_enclave: platform_create_enclave
create_enclave: validate_and_hash_enclave
[keystone-test]Edge init
[keystone-test]Enclave run
run_enclave: context_switch_to_enclave
[keystone-test]Enclave finish
testing loop
[keystone-test]Start test runner
[keystone-test]Enclave init: eapp_file loop, rt_file eyrie-rt
[  236.898162] keystone_enclave: epm allocated 4096 page(s) @ 00000000aa000000, CMA=1
[  237.150756] keystone_enclave: utm allocated 512 page(s) @ ffffffe003a00000
[  238.348785] keystone_enclave: epm: addr 00000000aa000000, size 16777216; utm: addr 00000000a3c00000, size 2097152
create_enclave: check runtime param
[create args info]:
        epm_addr: aa000000
        epmsize: 1000000
        utm_addr: a3c00000
        utmsize: 200000
        runtime_addr: aa003000
        user_addr: aa01e000
        free_addr: aa027000
create_enclave: allocate eid
create_enclave: setup PMP regions
create_enclave: cleanup memory regions
create_enclave: Init enclave state
create_enclave: platform_create_enclave
create_enclave: validate_and_hash_enclave
[keystone-test]Edge init
[keystone-test]Enclave run
run_enclave: context_switch_to_enclave
[keystone-test]Enclave finish
testing malloc
[keystone-test]Start test runner
[keystone-test]Enclave init: eapp_file malloc, rt_file eyrie-rt
[  309.223358] keystone_enclave: epm allocated 4096 page(s) @ 00000000aa000000, CMA=1
[  309.478668] keystone_enclave: utm allocated 512 page(s) @ ffffffe003a00000
[  310.678649] keystone_enclave: epm: addr 00000000aa000000, size 16777216; utm: addr 00000000a3c00000, size 2097152
create_enclave: check runtime param
[create args info]:
        epm_addr: aa000000
        epmsize: 1000000
        utm_addr: a3c00000
        utmsize: 200000
        runtime_addr: aa003000
        user_addr: aa01e000
        free_addr: aa028000
create_enclave: allocate eid
create_enclave: setup PMP regions
create_enclave: cleanup memory regions
create_enclave: Init enclave state
create_enclave: platform_create_enclave
create_enclave: validate_and_hash_enclave
[keystone-test]Edge init
[keystone-test]Enclave run
run_enclave: context_switch_to_enclave
[keystone-test]Enclave finish
testing long-nop
[keystone-test]Start test runner
[keystone-test]Enclave init: eapp_file long-nop, rt_file eyrie-rt
[  379.961853] keystone_enclave: epm allocated 4096 page(s) @ 00000000aa000000, CMA=1
[  380.230834] keystone_enclave: utm allocated 512 page(s) @ ffffffe003a00000
[  381.439758] keystone_enclave: epm: addr 00000000aa000000, size 16777216; utm: addr 00000000a3c00000, size 2097152
create_enclave: check runtime param
[create args info]:
        epm_addr: aa000000
        epmsize: 1000000
        utm_addr: a3c00000
        utmsize: 200000
        runtime_addr: aa003000
        user_addr: aa01e000
        free_addr: aa02b000
create_enclave: allocate eid
create_enclave: setup PMP regions
create_enclave: cleanup memory regions
create_enclave: Init enclave state
create_enclave: platform_create_enclave
create_enclave: validate_and_hash_enclave
[keystone-test]Edge init
[keystone-test]Enclave run
run_enclave: context_switch_to_enclave
[keystone-test]Enclave finish
testing fibonacci
[keystone-test]Start test runner
[keystone-test]Enclave init: eapp_file fibonacci, rt_file eyrie-rt
[  451.066253] keystone_enclave: epm allocated 4096 page(s) @ 00000000aa000000, CMA=1
[  451.314727] keystone_enclave: utm allocated 512 page(s) @ ffffffe003a00000
[  452.511444] keystone_enclave: epm: addr 00000000aa000000, size 16777216; utm: addr 00000000a3c00000, size 2097152
create_enclave: check runtime param
[create args info]:
        epm_addr: aa000000
        epmsize: 1000000
        utm_addr: a3c00000
        utmsize: 200000
        runtime_addr: aa003000
        user_addr: aa01e000
        free_addr: aa027000
create_enclave: allocate eid
create_enclave: setup PMP regions
create_enclave: cleanup memory regions
create_enclave: Init enclave state
create_enclave: platform_create_enclave
create_enclave: validate_and_hash_enclave
[keystone-test]Edge init
[keystone-test]Enclave run
run_enclave: context_switch_to_enclave
[keystone-test]Enclave finish
testing fib-bench
[keystone-test]Start test runner
[keystone-test]Enclave init: eapp_file fib-bench, rt_file eyrie-rt
[  562.407653] keystone_enclave: epm allocated 4096 page(s) @ 00000000aa000000, CMA=1
[  562.658294] keystone_enclave: utm allocated 512 page(s) @ ffffffe003a00000
[  563.855041] keystone_enclave: epm: addr 00000000aa000000, size 16777216; utm: addr 00000000a3c00000, size 2097152
create_enclave: check runtime param
[create args info]:
        epm_addr: aa000000
        epmsize: 1000000
        utm_addr: a3c00000
        utmsize: 200000
        runtime_addr: aa003000
        user_addr: aa01e000
        free_addr: aa027000
create_enclave: allocate eid
create_enclave: setup PMP regions
create_enclave: cleanup memory regions
create_enclave: Init enclave state
create_enclave: platform_create_enclave
create_enclave: validate_and_hash_enclave
 [keystone-test]Edge init
[keystone-test]Enclave run
run_enclave: context_switch_to_enclave
[keystone-test]Enclave finish
testing attestation
[keystone-test]Start test runner
[keystone-test]Enclave init: eapp_file attestation, rt_file eyrie-rt
[  673.840545] keystone_enclave: epm allocated 4096 page(s) @ 00000000aa000000, CMA=1
[  674.096191] keystone_enclave: utm allocated 512 page(s) @ ffffffe003a00000
[  675.289031] keystone_enclave: epm: addr 00000000aa000000, size 16777216; utm: addr 00000000a3c00000, size 2097152
create_enclave: check runtime param
[create args info]:
        epm_addr: aa000000
        epmsize: 1000000
        utm_addr: a3c00000
        utmsize: 200000
        runtime_addr: aa003000
        user_addr: aa01e000
        free_addr: aa028000
create_enclave: allocate eid
create_enclave: setup PMP regions
create_enclave: cleanup memory regions
create_enclave: Init enclave state
create_enclave: platform_create_enclave
create_enclave: validate_and_hash_enclave
[keystone-test]Edge init
[keystone-test]Enclave run
run_enclave: context_switch_to_enclave
Attestation report SIGNATURE is valid
[keystone-test]Enclave finish
testing untrusted
[keystone-test]Start test runner
[keystone-test]Enclave init: eapp_file untrusted, rt_file eyrie-rt
[  745.107574] keystone_enclave: epm allocated 4096 page(s) @ 00000000aa000000, CMA=1
[  745.364257] keystone_enclave: utm allocated 512 page(s) @ ffffffe003a00000
[  746.574218] keystone_enclave: epm: addr 00000000aa000000, size 16777216; utm: addr 00000000a3c00000, size 2097152
create_enclave: check runtime param
[create args info]:
        epm_addr: aa000000
        epmsize: 1000000
        utm_addr: a3c00000
        utmsize: 200000
        runtime_addr: aa003000
        user_addr: aa01e000
        free_addr: aa028000
create_enclave: allocate eid
create_enclave: setup PMP regions
create_enclave: cleanup memory regions
create_enclave: Init enclave state
create_enclave: platform_create_enclave
create_enclave: validate_and_hash_enclave
[keystone-test]Edge init
[keystone-test]Enclave run
run_enclave: context_switch_to_enclave
Enclave said: hello world!
Enclave said: 2nd hello world!
Enclave said value: 13
Enclave said value: 20
[keystone-test]Enclave finish
testing data-sealing
[keystone-test]Start test runner
[keystone-test]Enclave init: eapp_file data-sealing, rt_file eyrie-rt
[  815.870300] keystone_enclave: epm allocated 4096 page(s) @ 00000000aa000000, CMA=1
[  816.127655] keystone_enclave: utm allocated 512 page(s) @ ffffffe003a00000
[  817.341125] keystone_enclave: epm: addr 00000000aa000000, size 16777216; utm: addr 00000000a3c00000, size 2097152
create_enclave: check runtime param
[create args info]:
        epm_addr: aa000000
        epmsize: 1000000
        utm_addr: a3c00000
        utmsize: 200000
        runtime_addr: aa003000
        user_addr: aa01e000
        free_addr: aa028000
create_enclave: allocate eid
create_enclave: setup PMP regions
create_enclave: cleanup memory regions
create_enclave: Init enclave state
create_enclave: platform_create_enclave
create_enclave: validate_and_hash_enclave
[keystone-test]Edge init
[keystone-test]Enclave run
run_enclave: context_switch_to_enclave
Enclave said: Sealing key derivation successful!
[keystone-test]Enclave finish
#
# ./test-runner fibonacci eyrie-rt
[keystone-test]Start test runner
[keystone-test]Enclave init: eapp_file fibonacci, rt_file eyrie-rt
[  937.429534] keystone_enclave: epm allocated 4096 page(s) @ 00000000aa000000, CMA=1
[  937.682403] keystone_enclave: utm allocated 512 page(s) @ ffffffe003a00000
[  938.896301] keystone_enclave: epm: addr 00000000aa000000, size 16777216; utm: addr 00000000a3c00000, size 2097152
create_enclave: check runtime param
[create args info]:
        epm_addr: aa000000
        epmsize: 1000000
        utm_addr: a3c00000
        utmsize: 200000
        runtime_addr: aa003000
        user_addr: aa01e000
        free_addr: aa027000
create_enclave: allocate eid
create_enclave: setup PMP regions
create_enclave: cleanup memory regions
create_enclave: Init enclave state
create_enclave: platform_create_enclave
create_enclave: validate_and_hash_enclave
[keystone-test]Edge init
[keystone-test]Enclave run
run_enclave: context_switch_to_enclave
[keystone-test]Enclave finish
# ls /dev/keystone_enclave
/dev/keystone_enclave
# ls -l /dev/keystone_enclave
crw-rw----    1 root     root       10,  63 Jan  1 00:01 /dev/keystone_enclave
#
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

## Keystone Enclave Run Instructions

[**Keystone Enclave**](https://keystone-enclave.org/) is an open framework for architecting trusted execution environment.

We just integrated keystone enclave into Nuclei Linux SDK for quick evaluation on our FPGA Evaluation board.

* The keystone secure monitor is integrated in *opensbi/lib/utils/experimental*, and opensbi is adapted to support keystone secure monitor.
* The keystone sdk is located in *keystone-sdk*
* The keystone linux driver is located in *linux-keystone-driver*
* *bootrom* is also introduced, which is mainly used to measure secure monitor code
* linux kernel patch, and uboot update, and kernel and buildroot configurations all changed

To use keystone enclave, make sure you have internet access to github.com, since during building keystone, some repos
need to be cloned from github.

Build and run linux steps are just the same as above, the keystone sdk, keystone linux driver and its examples will be built and installed into rootfs.

Here we will just show steps when you have login the riscv linux console.

* list the files located in root directory via `ls`
* Install keystone enclave linux module via `insmod keystone-enclave.ko`
* Check whether keystone enclave kernel module exist in `/dev/keystone-enclave`
* Extract tests applications to *tests* folder via `./tests.ke --target tests --noexec`
* Change directory to *tests* folder and check the tests via `cd tests && ls`
* The `test-runner` is the test runner application to run enclave examples, the `eyrie-rt` is the 
  keystone eyrie runtime, the other files except `run-test.sh` are all keystone enclave examples.
* Then you can run all the tests via command `./run-test.sh`
* Or you can run single test case such as `fibonacci` via command `./test-runner fibonacci eyrie-rt`

> Keystone enclave currently only tested and worked on FPGA evaluation board, not on xl-spike.

About the run log, please see above run log in real FPGA evaluation board.

For more details about the design of keystone enclave, please visit https://docs.keystone-enclave.org/

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

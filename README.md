# Nuclei Linux SDK

[![Build](https://github.com/Nuclei-Software/nuclei-linux-sdk/workflows/Build/badge.svg)](https://github.com/Nuclei-Software/nuclei-linux-sdk/actions)

> Normal development of Nuclei Linux SDK are switched to *dev_nuclei_next* branch, other branchs such as
> *dev_nuclei* are not recommended.

This will download external prebuilt toolchain, and build linux kernel, device tree, ramdisk,
and opensbi with linux kernel payload for Nuclei xl-spike which can emulate Nuclei Demo SoC.

It can also build linux kernel, rootfs ramdisk, opensbi and freeloader for Nuclei Demo SoC
FPGA bitstream running in Nuclei FPGA Evaluation Board.

Nuclei Demo SoC is mainly used for evaluation, which can be configured to use Nuclei RISC-V Core.

If you want to run linux on Nuclei Demo SoC, you will need UX600 or UX900 RISC-V Core present in it.

> The rootfs used in this SDK is initramfs format.

> * If you want to boot evaluate TEE feature, please checkout these branches:
>   - *dev_nuclei_keystone*: Keystone TEE porting for Nuclei RISC-V Core
>   - *dev_flash_penglai_spmp*: Penglai TEE porting for Nuclei RISC-V Core, sPMP required
>   - *dev_flash_spmp*: not TEE feature, just used to boot Nuclei RISC-V Core, sPMP required
>
> eg. You can switch to selected branch, eg. `dev_nuclei_keystone` branch via command below:
>   ~~~
>   # Please make sure your workspace is clean
>   git status
>   # Fetch latest change, and checkout dev_nuclei_keystone branch, and update submodules
>   git fetch -a
>   git checkout dev_nuclei_keystone
>   git submodule init
>   # --depth 1 is used to clone less source code
>   git submodule update --depth 1
>   # make sure the workspace is clean and your are on branch dev_nuclei_keystone now 
>   git status
>   ~~~
> * The documentation in `dev_nuclei_keystone` branch is also updated according to its feature.

## Tested Configurations

### Ubuntu 20.04 x86_64 host

- Status: Working
- Build dependencies
  - packages: `build-essential git python3 python3-pip autotools-dev make cmake texinfo bison minicom flex liblz4-tool libgmp-dev libmpfr-dev libmpc-dev gawk libz-dev libssl-dev device-tree-compiler libncursesw5-dev libncursesw5 mtools`
  - python pips: `git-archive-all`
- Get prebuilt openocd from [Nuclei Development Tools](https://nucleisys.com/download.php#tools)
- Setup openocd and add it into **PATH**
- mtools version >= 4.0.24

## Build Instructions

### Install Dependencies

Install the software dependencies required by this SDK using command:

~~~shell
sudo apt-get install build-essential git python3 python3-pip autotools-dev cmake texinfo bison minicom flex liblz4-tool \
   libgmp-dev libmpfr-dev libmpc-dev gawk libz-dev libssl-dev device-tree-compiler libncursesw5-dev libncursesw5 mtools
sudo pip3 install git-archive-all
~~~

### Install Nuclei Tools

Download prebuilt 64bit `openocd` tool and `qemu` from [Nuclei Development Tools](https://nucleisys.com/download.php#tools),
and extract it into your PC, and then setup **PATH** using this command:

> \>= 2022.01 release is required. You can install Nuclei Studio, which contains prebuilt gcc/openocd/qemu

~~~shell
# Make sure you changed /path/to/openocd/bin and /path/to/qemu/bin to the real path of your PC
export PATH=/path/to/openocd/bin:/path/to/qemu/bin:$PATH
# Check path is set correctly
which openocd qemu-system-riscv64
~~~

### Clone Repo

* Checkout this repository using `git`.

  - If you have good network access to github, you can clone this repo using command
    `git clone https://github.com/Nuclei-Software/nuclei-linux-sdk`
  - Otherwise, you can try with our mirror maintained in gitee using command
    `git clone https://gitee.com/Nuclei-Software/nuclei-linux-sdk`
  - If https is not stable, you can try ssh, please search about git clone ssh/https difference

* Then you will need to checkout all of the linked submodules using:

  ~~~shell
  cd nuclei-linux-sdk
  # the following command might fail due to network connection issue
  # you can clone less code with --depth=1
  git submodule update --recursive --init
  # if you want to clone less source code to speed up or make clone stable, please add extra --depth=1
  # --depth=1 is used to do shallow clone, see https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt---depth
  # git submodule update --init --depth=1
  ~~~

* To make sure you have checked out clean source code, you need to run `git status` command,
  and get expected output as below:

  ~~~
  On branch dev_nuclei_next
  Your branch is up to date with 'origin/dev_nuclei_next'.

  nothing to commit, working tree clean
  ~~~

* If you have trouble in get clean working tree, you can try command
  `git submodule update --recursive --init --depth=1` again, you might need to
  retry several times depending on your network access speed.
* If you still have issues, please check FAQ sections at the bottom of this README.md

This will take some time and require around 2GB of disk space. Some modules may
fail because certain dependencies don't have the best git hosting. The only
solution is to wait and try again later (or ask someone for a copy of that
source repository).

### Update source code

Update source code if there are new commits in this repo.

Assume currently you are in `dev_nuclei_next` branch, and the working tree is clean.

Then you run the following command to update this repo:

~~~shell
# Pull lastest source code and rebase your local commits onto it
git pull --rebase origin dev_nuclei_next
# Update git submodules
git submodule update
# Check workspace status to see whether it is clean
git status
~~~

## Show Help

You can run `make help` to show help message about how to use this Nuclei Linux SDK.

But if you want to change and adapt for your SoC, you need to understand the build system in Makefile.

## Nuclei Linux SDK Integration

Here are the version numbers of sub projects used in Nuclei Linux SDK.

* Linux 5.10
* Uboot v2021.01
* OpenSBI v0.9
* Buildroot 2020.11.2

Our changes to support Nuclei Demo SoC are adapted based on above version.

## Modify Build Configuration

You can choose different core configuration by modify the `CORE ?= ux600` line in `Makefile`.

We support four configurations for **CORE**, choose the right core according to your configuration:

* `ux600` or `ux900`: rv64imac RISC-V CORE configuration without FPU.
* `ux600fd` or `ux900fd`: rv64imafdc RISC-V CORE configuration with FPU.

You can choose different SoC by modify `SOC ?= demosoc` line in `Makefile`.

* `demosoc`: The demostration SoC from nuclei
* `evalsoc`: The next generation of the `demosoc`, we call it `demosoc`, when your cpu has `iregion` feature, please use this one
* you can add your SoC support by adding configuration in `conf/$SOC` folder

You can choose different boot mode by modify the `BOOT_MODE ?= sd` line in `Makefile`.

* `sd`: boot from flash + sdcard, extra SDCard is required(kernel, rootfs, dtb placed in it)
* `flash`: boot from flash only, flash will contain images placed in sdcard of sd boot mode, at least 8M flash is required, current onboard mcu-flash of DDR200T is only 4M, so this feature is not ready for it.

Please modify the `Makefile` to your correct core configuration before build any source code.

For each SoC, in `conf/$SOC/`, it contains a `build.mk` you can specify qemu, timer/cpu/peripheral hz.

* **TIMER_HZ**: implementation dependent, you can change timer frequency to different value to overwrite the one in dts.
* **CPU_HZ**: implementation dependent, you can change cpu frequency to different value to overwrite the one in dts.
* **PERIPH_HZ**: implementation dependent, you can change peripheral frequency to different value to overwrite the one in dts.
* **SIMULATION**: implementation dependent, if SIMULATION=1, only the peripherals can be simulated in rtl will be present in dts, for demosoc/evalsoc, only uart will be present, qspi will not.

> `TIMER_HZ/CPU_HZ/PERIPH_HZ` are all implementation dependent, it required your SoC dts implement this feature, currently
> demosoc/evalsoc all support this.

For each SoC, in `conf/$SOC`, it also contains a `freeloader.mk`, it is used to configure freeloader feature to set cpu configuration when bring up, such as configure cache, tlb, smp feature, for details, please refer to freeloader source code.

* **Deprecated**: If you want to compile and run using simulator *xl-spike*, please
  check steps mentioned in [Booting Linux on Nuclei xl-spike](#Booting-Linux-on-Nuclei-xl-spike)
* If you want to compile and run using FPGA evaluation board, please
  check steps mentioned in [Booting Linux on Nuclei FPGA Evaluation Board](#Booting-Linux-on-Nuclei-FPGA-Evaluation-Board)

## Booting Linux on Nuclei xl-spike

**Note**: `xl_spike` tool should be installed and added into **PATH** in advance.
Contact with our sales via email **contact@nucleisys.com** to get `xl_spike` tools.

> This feature is **deprecated** now.

### Run on xl_spike 

If you have run `make bootimages` command before, please make sure you run `make presim` to prepare
build environment for running linux in simulation.

When toolchain steps are finished, then, you can build buildroot, linux and opensbi,
and run opensbi with linux payload on xlspike by running `make sim`.

Here is sample output running in xl_spike:

~~~
xl_spike --isa=rv64imac /home/hqfang/workspace/software/nuclei-linux-sdk/work/demosoc/opensbi/platform/nuclei/demosoc/firmware/fw_payload.elf
rv64 file
call xl_spike_t construct function
warning: tohost and fromhost symbols not in ELF; can't communicate with target
UART: 
UART: OpenSBI v0.9
UART:    ____                    _____ ____ _____
UART:   / __ \                  / ____|  _ \_   _|
UART:  | |  | |_ __   ___ _ __ | (___ | |_) || |
UART:  | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
UART:  | |__| | |_) |  __/ | | |____) | |_) || |_
UART:   \____/| .__/ \___|_| |_|_____/|____/_____|
UART:         | |
UART:         |_|
UART: 
UART: Platform Name             : Nuclei Demo SoC
UART: Platform Features         : timer,mfdeleg
UART: Platform HART Count       : 1
UART: Firmware Base             : 0xa0000000
UART: Firmware Size             : 84 KB
UART: Runtime SBI Version       : 0.2
UART: 
UART: Domain0 Name              : root
UART: Domain0 Boot HART         : 0
UART: Domain0 HARTs             : 0*
UART: Domain0 Region00          : 0x00000000a0000000-0x00000000a001ffff ()
UART: Domain0 Region01          : 0x0000000000000000-0xffffffffffffffff (R,W,X)
UART: Domain0 Next Address      : 0x00000000a0400000
UART: Domain0 Next Arg1         : 0x00000000a8000000
UART: Domain0 Next Mode         : S-mode
UART: Domain0 SysReset          : yes
UART: 
UART: Boot HART ID              : 0
UART: Boot HART Domain          : root
UART: Boot HART ISA             : rv64imacsu
UART: Boot HART Features        : scounteren,mcounteren,time
UART: Boot HART PMP Count       : 16
UART: Boot HART PMP Granularity : 4
UART: Boot HART PMP Address Bits: 54
UART: Boot HART MHPM Count      : 0
UART: Boot HART MHPM Count      : 0
UART: Boot HART MIDELEG         : 0x0000000000000222
UART: Boot HART MEDELEG         : 0x000000000000b109
UART: [    0.000000] Linux version 5.10.0+ (hqfang@softserver) (riscv-nuclei-linux-gnu-gcc (GCC) 9.2.0, GNU ld (GNU Binutils) 2.32) #1 Fri Mar 19 14:47:22 CST 2021
UART: [    0.000000] OF: fdt: Ignoring memory range 0xa0000000 - 0xa0400000
UART: [    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
UART: [    0.000000] printk: bootconsole [sbi0] enabled
UART: [    0.000000] efi: UEFI not found.
UART: [    0.000000] Zone ranges:
UART: [    0.000000]   DMA32    [mem 0x00000000a0400000-0x00000000afffffff]
UART: [    0.000000]   Normal   empty
UART: [    0.000000] Movable zone start for each node
UART: [    0.000000] Early memory node ranges
UART: [    0.000000]   node   0: [mem 0x00000000a0400000-0x00000000afffffff]
UART: [    0.000000] Initmem setup node 0 [mem 0x00000000a0400000-0x00000000afffffff]
UART: [    0.000000] software IO TLB: mapped [mem 0x00000000abc8b000-0x00000000afc8b000] (64MB)
UART: [    0.000000] SBI specification v0.2 detected
UART: [    0.000000] SBI implementation ID=0x1 Version=0x9
UART: [    0.000000] SBI v0.2 TIME extension detected
UART: [    0.000000] SBI v0.2 IPI extension detected
UART: [    0.000000] SBI v0.2 RFENCE extension detected
UART: [    0.000000] riscv: ISA extensions acim
UART: [    0.000000] riscv: ELF capabilities acim
UART: [    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 63630
UART: [    0.000000] Kernel command line: earlycon=sbi
UART: [    0.000000] Dentry cache hash table entries: 32768 (order: 6, 262144 bytes, linear)
UART: [    0.000000] Inode-cache hash table entries: 16384 (order: 5, 131072 bytes, linear)
UART: [    0.000000] Sorting __ex_table...
UART: [    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
UART: [    0.000000] Memory: 172900K/258048K available (2696K kernel code, 2811K rwdata, 2048K rodata, 128K init, 280K bss, 85148K reserved, 0K cma-reserved)
UART: [    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
UART: [    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
UART: [    0.000000] riscv-intc: 64 local interrupts mapped
UART: [    0.000000] plic: interrupt-controller@8000000: mapped 53 interrupts with 1 handlers for 2 contexts.
UART: [    0.000000] random: get_random_bytes called from 0xffffffe000002910 with crng_init=0
UART: [    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
UART: [    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x179dd7f66, max_idle_ns: 28210892933900 ns
UART: [    0.001760] sched_clock: 64 bits at 100kHz, resolution 10000ns, wraps every 35184372085000ns
UART: [    0.022800] printk: console [hvc0] enabled
UART: [    0.022800] printk: console [hvc0] enabled
UART: [    0.041290] printk: bootconsole [sbi0] disabled
UART: [    0.041290] printk: bootconsole [sbi0] disabled
UART: [    0.065580] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.20 BogoMIPS (lpj=1000)
UART: [    0.089740] pid_max: default: 32768 minimum: 301
UART: [    0.132740] Mount-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
UART: [    0.152020] Mountpoint-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
UART: [    0.324900] EFI services will not be available.
UART: [    0.359550] devtmpfs: initialized
UART: [    0.519290] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
UART: [    0.543440] futex hash table entries: 256 (order: 0, 6144 bytes, linear)
UART: [    0.566050] pinctrl core: initialized pinctrl subsystem
UART: [    0.620770] NET: Registered protocol family 16
UART: [    1.452200] clocksource: Switched to clocksource riscv_clocksource
UART: [    1.624680] NET: Registered protocol family 2
UART: [    1.795650] tcp_listen_portaddr_hash hash table entries: 256 (order: 0, 4096 bytes, linear)
UART: [    1.818280] TCP established hash table entries: 2048 (order: 2, 16384 bytes, linear)
UART: [    1.849690] TCP bind hash table entries: 2048 (order: 2, 16384 bytes, linear)
UART: [    1.877280] TCP: Hash tables configured (established 2048 bind 2048)
UART: [    1.904640] UDP hash table entries: 256 (order: 1, 8192 bytes, linear)
UART: [    1.925370] UDP-Lite hash table entries: 256 (order: 1, 8192 bytes, linear)
UART: [    1.970120] NET: Registered protocol family 1
UART: [    2.043020] RPC: Registered named UNIX socket transport module.
UART: [    2.057540] RPC: Registered udp transport module.
UART: [    2.069730] RPC: Registered tcp transport module.
UART: [    2.082040] RPC: Registered tcp NFSv4.1 backchannel transport module.
UART: [    9.297610] workingset: timestamp_bits=62 max_order=16 bucket_order=0
UART: [   10.637960] io scheduler mq-deadline registered
UART: [   10.649850] io scheduler kyber registered
UART: [   18.585530] brd: module loaded
UART: [   19.555270] loop: module loaded
UART: [   19.697090] NET: Registered protocol family 17
UART: [   19.780090] Freeing unused kernel memory: 128K
UART: [   19.799080] Run /init as init process
UART: Starting syslogd: OK
UART: Starting klogd: OK
UART: Running sysctl: OK
UART: Starting mdev... OK
UART: modprobe: can't change directory to '/lib/modules': No such file or directory
UART: Saving random seed: [  130.621540] random: dd: uninitialized urandom read (512 bytes read)
UART: OK
UART: 
UART: Welcome to Nuclei System Techology
nucleisys login: root
root
UART: Password: nuclei

UART: # cat /proc/cpuinfo
cat /proc/cpuinfo
UART: processor	: 0
UART: hart		: 0
UART: isa		: rv64imac
UART: mmu		: sv39
UART: 
UART: # uname -a
uname -a
UART: Linux nucleisys 5.10.0+ #1 Fri Mar 19 14:47:22 CST 2021 riscv64 GNU/Linux
UART: # ls /
ls /
UART: bin      init     linuxrc  opt      run      tmp
UART: dev      lib      media    proc     sbin     usr
UART: etc      lib64    mnt      root     sys      var
UART: # 
~~~

If you want to remove the login, and directly enter to bash, please check [**Known issues and FAQ**](#Known-issues-and-FAQs).

## Booting Linux on Nuclei QEMU

**Note**: `qemu-system-riscv64` tool should be installed and added into **PATH** in advance.

In release 2022.01 version of Nuclei QEMU, the Nuclei System Timer implementation has some issue, you need to change the
**TIMERCLK_FREQ** in `conf/demosoc/*.dts` from 32768 to 1000000 before you run on qemu via `TIMER_HZ` in `conf/$SOC/build.mk`.

> Sometimes 1000000 may still face issue below, change it to larger value, such as 4000000
> Now you can change the timer frequency directly using TIMER_HZ=1000000 via make command such as
> `make CORE=ux900fd SOC=evalsoc TIMER_HZ=1000000 run_qemu`

If you don't change it, you will met the following issue when run on qemu.

~~~
[   43.310821] smp: Bringing up secondary CPUs ...
[  236.345489] rcu: INFO: rcu_sched detected stalls on CPUs/tasks:
[  236.767517]  (detected by 2, t=2104 jiffies, g=-1191, q=1)
[  237.065216] rcu: All QSes seen, last rcu_sched kthread activity 20 (4294941899-4294941879), jiffies_till_next_fqs=1, root ->qsmask 0x0
[  853.952209] rcu: INFO: rcu_sched detected stalls on CPUs/tasks:
[  854.333374]  (detected by 0, t=2102 jiffies, g=-1183, q=0)
[  854.724243] rcu: All QSes seen, last rcu_sched kthread activity 1213 (4294950595-4294949382), jiffies_till_next_fqs=1, root ->qsmask 0x0
[  855.354614] rcu: rcu_sched kthread starved for 1213 jiffies! g-1183 f0x2 RCU_GP_CLEANUP(7) ->state=0x0 ->cpu=0
[  855.864868] rcu:     Unless rcu_sched kthread gets sufficient CPU time, OOM is now expected behavior.
[  856.289337] rcu: RCU grace-period kthread stack dump:
[  856.695190] task:rcu_sched       state:R  running task     stack:    0 pid:   10 ppid:     2 flags:0x00000008
[  857.327423] Call Trace:
[  857.533020] [<ffffffe000202450>] 0xffffffe000202450
[  857.779937] [<ffffffe00067bb3c>] 0xffffffe00067bb3c
[  858.008209] [<ffffffe000225d58>] 0xffffffe000225d58
~~~

> If you changed it here, don't forget to change it back when you run on hardware.

When the required changes has been done, then you can run `make run_qemu` to run riscv linux on Nuclei QEMU, here are the sample output.

~~~
Run on qemu for simulation
qemu-system-riscv64 -M nuclei_u,download=flashxip -smp 8 -m 256M -bios /home/hqfang/workspace/software/nuclei-linux-sdk/work/demosoc/freeloader/freeloader.elf -nographic -drive file=/home/hqfang/workspace/software/nuclei-linux-sdk/work/demosoc/disk.img,if=sd,format=raw

OpenSBI v0.9
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name             : Nuclei Demo SoC
Platform Features         : timer,mfdeleg
Platform HART Count       : 8
Firmware Base             : 0xa0000000
Firmware Size             : 152 KB
Runtime SBI Version       : 0.2

Domain0 Name              : root
Domain0 Boot HART         : 3
Domain0 HARTs             : 0*,1*,2*,3*,4*,5*,6*,7*
Domain0 Region00          : 0x00000000a0000000-0x00000000a003ffff ()
Domain0 Region01          : 0x0000000000000000-0xffffffffffffffff (R,W,X)
Domain0 Next Address      : 0x00000000a0200000
Domain0 Next Arg1         : 0x00000000a8000000
Domain0 Next Mode         : S-mode
Domain0 SysReset          : yes

Boot HART ID              : 3
Boot HART Domain          : root
Boot HART ISA             : rv64imafdcsu
Boot HART Features        : scounteren,mcounteren
Boot HART PMP Count       : 16
Boot HART PMP Granularity : 4
Boot HART PMP Address Bits: 54
Boot HART MHPM Count      : 0
Boot HART MHPM Count      : 0
Boot HART MIDELEG         : 0x0000000000000222
Boot HART MEDELEG         : 0x000000000000b109


U-Boot 2021.01-00018-g689711afb6 (Feb 22 2022 - 16:02:44 +0800)

CPU:   rv64imac
Model: nuclei,demo-soc
DRAM:  224 MiB
Board: Initialized
MMC:   Nuclei SPI version 0x0
spi@10034000:mmc@0: 0
In:    serial@10013000
Out:   serial@10013000
Err:   serial@10013000
Net:   No ethernet found.
Hit any key to stop autoboot:  0 
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
314 bytes read in 1239 ms (0 Bytes/s)
## Executing script at a0200000
Loading kernel
3969713 bytes read in 156479 ms (24.4 KiB/s)
Loading ramdisk
3588531 bytes read in 131421 ms (26.4 KiB/s)
Loading dtb
5005 bytes read in 1372 ms (2.9 KiB/s)
Starts booting from SD
## Booting kernel from Legacy Image at a1000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    3969649 Bytes = 3.8 MiB
   Load Address: a0400000
   Entry Point:  a0400000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at a8300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    3588467 Bytes = 3.4 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at a8000000
   Booting using the fdt blob at 0xa8000000
   Uncompressing Kernel Image
   Using Device Tree in place at 00000000a8000000, end 00000000a800438c

Starting kernel ...

[    0.000000] Linux version 5.10.0+ (hqfang@whss1.corp.nucleisys.com) (riscv-nuclei-linux-gnu-gcc (GCC) 9.2.0, GNU ld (GNU Binutils) 2.32) #10 SMP Tue Feb 22 16:02:58 CST 2022
[    0.000000] OF: fdt: Ignoring memory range 0xa0000000 - 0xa0400000
[    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
[    0.000000] printk: bootconsole [sbi0] enabled
[    0.000000] efi: UEFI not found.
[    0.000000] Initial ramdisk at: 0x(____ptrval____) (3592192 bytes)
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x00000000a0400000-0x00000000adffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x00000000a0400000-0x00000000adffffff]
[    0.000000] Initmem setup node 0 [mem 0x00000000a0400000-0x00000000adffffff]
[    0.000000] software IO TLB: mapped [mem 0x00000000a9cf6000-0x00000000adcf6000] (64MB)
[    0.000000] SBI specification v0.2 detected
[    0.000000] SBI implementation ID=0x1 Version=0x9
[    0.000000] SBI v0.2 TIME extension detected
[    0.000000] SBI v0.2 IPI extension detected
[    0.000000] SBI v0.2 RFENCE extension detected
[    0.000000] SBI v0.2 HSM extension detected
[    0.000000] riscv: ISA extensions acim
[    0.000000] riscv: ELF capabilities acim
[    0.000000] percpu: Embedded 16 pages/cpu s25112 r8192 d32232 u65536
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 55550
[    0.000000] Kernel command line: earlycon=sbi console=ttyNUC0
[    0.000000] Dentry cache hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    0.000000] Inode-cache hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    0.000000] Sorting __ex_table...
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Memory: 138488K/225280K available (4630K kernel code, 4236K rwdata, 2048K rodata, 188K init, 328K bss, 86792K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=8, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped
[    0.000000] plic: interrupt-controller@8000000: mapped 53 interrupts with 8 handlers for 16 contexts.
[    0.000000] random: get_random_bytes called from 0xffffffe000002964 with crng_init=0
[    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [3]
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1d854df40, max_idle_ns: 3526361616960 ns
[    0.002102] sched_clock: 64 bits at 1000kHz, resolution 1000ns, wraps every 2199023255500ns
[    0.070308] Calibrating delay loop (skipped), value calculated using timer frequency.. 2.00 BogoMIPS (lpj=10000)
[    0.077789] pid_max: default: 32768 minimum: 301
[    0.098567] Mount-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.104127] Mountpoint-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.451876] rcu: Hierarchical SRCU implementation.
[    0.482610] EFI services will not be available.
[    0.512234] smp: Bringing up secondary CPUs ...
[    0.960606] smp: Brought up 1 node, 8 CPUs
[    1.131679] devtmpfs: initialized
[    1.277124] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    1.295969] futex hash table entries: 2048 (order: 5, 131072 bytes, linear)
[    1.329397] pinctrl core: initialized pinctrl subsystem
[    1.378872] NET: Registered protocol family 16
[    2.208682] clocksource: Switched to clocksource riscv_clocksource
[    2.481729] NET: Registered protocol family 2
[    2.646425] tcp_listen_portaddr_hash hash table entries: 256 (order: 0, 4096 bytes, linear)
[    2.661005] TCP established hash table entries: 2048 (order: 2, 16384 bytes, linear)
[    2.686031] TCP bind hash table entries: 2048 (order: 3, 32768 bytes, linear)
[    2.786416] TCP: Hash tables configured (established 2048 bind 2048)
[    2.854661] UDP hash table entries: 256 (order: 1, 8192 bytes, linear)
[    2.883822] UDP-Lite hash table entries: 256 (order: 1, 8192 bytes, linear)
[    2.944807] NET: Registered protocol family 1
[    3.072541] RPC: Registered named UNIX socket transport module.
[    3.094494] RPC: Registered udp transport module.
[    3.121129] RPC: Registered tcp transport module.
[    3.132405] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    3.364613] Trying to unpack rootfs image as initramfs...
[    6.252686] Freeing initrd memory: 3500K
[    6.605285] workingset: timestamp_bits=62 max_order=16 bucket_order=0
[    6.895276] jffs2: version 2.2. (NAND) © 2001-2006 Red Hat, Inc.
[    6.973105] JFS: nTxBlock = 1109, nTxLock = 8874
[    9.093525] NET: Registered protocol family 38
[    9.104896] io scheduler mq-deadline registered
[    9.122351] io scheduler kyber registered
[   13.506353] 10013000.serial: ttyNUC0 at MMIO 0x10013000 (irq = 1, base_baud = 0) is a Nuclei UART/USART
[   13.575060] printk: console [ttyNUC0] enabled
[   13.575060] printk: console [ttyNUC0] enabled
[   13.606097] printk: bootconsole [sbi0] disabled
[   13.606097] printk: bootconsole [sbi0] disabled
[   14.392907] brd: module loaded
[   14.715445] loop: module loaded
[   14.785078] nuclei_spi 10014000.spi: mapped; irq=2, cs=1
[   15.011696] spi-nor spi0.0: is25wp256 (32768 Kbytes)
[   15.951016] random: fast init done
[   25.933883] ftl_cs: FTL header not found.
[   26.045755] nuclei_spi 10034000.spi: mapped; irq=3, cs=1
[   26.161922] libphy: Fixed MDIO Bus: probed
[   26.285013] mmc_spi spi1.0: SD/MMC host mmc0, no DMA, no WP, no poweroff, cd polling
[   26.324278] ipip: IPv4 and MPLS over IPv4 tunneling driver
[   26.415723] NET: Registered protocol family 10
[   26.594376] Segment Routing with IPv6
[   26.612977] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[   26.686517] NET: Registered protocol family 17
[   27.196206] Freeing unused kernel memory: 188K
[   27.244514] mmc0: host does not support reading read-only switch, assuming write-enable
[   27.257332] mmc0: new SD card on SPI
[   27.282751] Run /init as init process
[   27.364843] mmcblk0: mmc0:0000 QEMU! 1.00 GiB 
[   28.246055]  mmcblk0: p1
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory
Saving random seed: [   90.144880] random: dd: uninitialized urandom read (512 bytes read)
OK

Welcome to Nuclei System Technology
nucleisys login: root
Password: 
# cat /proc/cpuinfo 
processor       : 0
hart            : 3
isa             : rv64imac
mmu             : sv39

processor       : 1
hart            : 0
isa             : rv64imac
mmu             : sv39

processor       : 2
hart            : 1
isa             : rv64imac
mmu             : sv39

processor       : 3
hart            : 2
isa             : rv64imac
mmu             : sv39

processor       : 4
hart            : 4
isa             : rv64imac
mmu             : sv39

processor       : 5
hart            : 5
isa             : rv64imac
mmu             : sv39

processor       : 6
hart            : 6
isa             : rv64imac
mmu             : sv39

processor       : 7
hart            : 7
isa             : rv64imac
mmu             : sv39

# mount /dev/mmcblk0 /mnt/
# ls /mnt/
boot.scr     kernel.dtb   uImage.lz4   uInitrd.lz4
~~~

## Booting Linux on Nuclei FPGA Evaluation Board

### Get Nuclei Demo SoC MCS from Nuclei

Contact with our sales via email **contact@nucleisys.com** to get FPGA bitstream for Nuclei
Demo SoC MCS and get guidance about how to program FPGA bitstream in the board.

Nuclei Demo SoC can be configured using Nuclei RISC-V Linux Capable Core such as UX600 and UX900,
To learn about Nuclei RISC-V Linux Capable Core, please check:

* [UX600 Series 64-Bit High Performance Application Processor](https://nucleisys.com/product.php?site=ux600)
* [900 Series 32/64-Bit High Performance Processor](https://nucleisys.com/product.php?site=900)

Nuclei FPGA Evaluation Board, DDR200T/KU060/VCU118 version is correct hardware to
run linux on it, click [Nuclei DDR200T Board](https://nucleisys.com/developboard.php#ddr200t) to learn about more.

### Apply changes for your SoC

Before compiling this source code, please make sure you have done the following changes.

Now we have two version of SoC for customer to evaluate our RISC-V CPU IP, if the bitstream you get from us
has the `iregion` feature, you should use `evalsoc`, otherwise choose `demosoc`.

If there is double float fpu in the bitstream supported, you should choose `ux600fd` or `ux900fd`.

If the cpu frequency is not 16MHz, you should change **CPUCLK_FREQ** in `nuclei_rv64imafdc.dts` and `nuclei_rv64imac.dts`
to match the correct frequency.

For example, you have get a bitstream which is our ux900 series cpu ip, with double float fpu, and cpu frequency is 100MHz.

You should change `SOC` to `evalsoc`, `CORE` to `ux900fd` in [Makefile](Makefile).

And change **CPUCLK_FREQ** in the `nuclei_rv64imafdc.dts` and `nuclei_rv64imac.dts` in `conf/$SOC/`(`conf/evalsoc` for this case).

### Build Freeloader

> Make sure you have network access to outside world, buildroot will download required packages in build steps.

*freeloader* is a first stage bootloader which contains *opensbi*, *uboot* and *dtb* binaries,
when bootup, it will enable I/D cache and load *opensbi*, *uboot* and *dtb* from onboard
norflash to DDR, and then goto entry of *opensbi*.

To build *freeloader*, you just need to run `make freeloader`

### Upload Freeloader to FPGA Evaluation Board

If you have connected your board to your Linux development environment, and setuped JTAG drivers,
then you can run `make upload_freeloader` to upload the *work/$SOC/freeloader/freeloader.elf* to your board.

You can also use `riscv-nuclei-elf-gdb` and `openocd` to download this program by yourself, for
simple steps, please see [Known issues and FAQs](#Known-issues-and-FAQs).

### Build SDCard Boot Images

If **BOOT_MODE** is set to `flash`, then no need to prepare the boot images, just program the
**freeloader.elf** to on board flash, but it required at least 8M flash.

If you have run `make sim` command before, please make sure you run `make preboot` to prepare
build environment for generate boot images.

If the freeloader is flashed to the board, then you can prepare the SDCard boot materials,
you can run `make bootimages` to generate the boot images to *work/$SOC/boot*, and an zip file
called *work/$SOC/boot.zip* , you can extract this *boot.zip* to your SDCard or copy all the files
located in *work/$SOC/boot*, make sure the files need to be put **right in the root of SDCard**,
then you can insert this SDCard to your SDCard slot(J57) beside the TFT LCD.

The contents of *work/$SOC/boot* or *work/$SOC/boot.zip* are as below:

* **kernel.dtb**  : optional, device tree binary file, this dtb is optional now, since freeloader.elf already contains dtb, we can use dtb inside freeloader.elf, and if you want to use a different device tree for linux kernel, you can change this dtb, and place it in sdcard, otherwise this dtb is not a required file for sdcard.
* **boot.scr**    : required, boot script used by uboot, generated from [./conf/demosoc/uboot.cmd](conf/demosoc/uboot.cmd)
* **uImage.lz4**  : required, lz4 archived kernel image
* **uInitrd.lz4** : required, lz4 archived rootfs image

> SDCard is recommended to use SDHC format.
> SDCard need to be formatted to `FAT32` format, with only 1 partition.

### Run Linux

When all above is done, you can reset the power on board, then opensbi will boot uboot, and
uboot will automatically load linux image and initramfs from SDCard and boot linux if everything
is prepared correctly.

If you met with issues, please check the [**Known issues and FAQ**](#Known-issues-and-FAQs).

The linux login user name and password is *root* and *nuclei*.

Sample output in **UART @ 115200bps, Data 8bit, Parity None, Stop Bits 1bit, No Flow Control**.

> **Flow control must be disabled in UART terminal**.

> UART baudrate changed from 57600bps to 115200bps, due to evaluation SoC frequency by default
> changed from 8MHz to 16MHz, and now uart can work correctly on 115200bps.

~~~
OpenSBI v0.9
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name             : Nuclei Demo SoC
Platform Features         : timer,mfdeleg
Platform HART Count       : 4
Firmware Base             : 0xa0000000
Firmware Size             : 120 KB
Runtime SBI Version       : 0.2

Domain0 Name              : root
Domain0 Boot HART         : 0
Domain0 HARTs             : 0*,1*,2*,3*
Domain0 Region00          : 0x00000000a0000000-0x00000000a001ffff ()
Domain0 Region01          : 0x0000000000000000-0xffffffffffffffff (R,W,X)
Domain0 Next Address      : 0x00000000a0200000
Domain0 Next Arg1         : 0x00000000a8000000
Domain0 Next Mode         : S-mode
Domain0 SysReset          : yes

Boot HART ID              : 0
Boot HART Domain          : root
Boot HART ISA             : rv64imafdcsu
Boot HART Features        : scounteren,mcounteren,time
Boot HART PMP Count       : 16
Boot HART PMP Granularity : 4096
Boot HART PMP Address Bits: 36
Boot HART MHPM Count      : 0
Boot HART MHPM Count      : 0
Boot HART MIDELEG         : 0x0000000000000222
Boot HART MEDELEG         : 0x000000000000b109


U-Boot 2021.01-00018-g689711afb6 (Nov 20 2021 - 08:44:44 +0800)

CPU:   rv64imac
Model: nuclei,demo-soc
DRAM:  256 MiB
Board: Initialized
MMC:   Nuclei SPI version 0x0
spi@10034000:mmc@0: 0
In:    serial@10013000
Out:   serial@10013000
Err:   serial@10013000
Net:   No ethernet found.
Hit any key to stop autoboot:  0
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
314 bytes read in 176 ms (1000 Bytes/s)
## Executing script at a0200000
Loading kernel
3969714 bytes read in 35517 ms (108.4 KiB/s)
Loading ramdisk
3588543 bytes read in 32133 ms (108.4 KiB/s)
Loading dtb
3861 bytes read in 208 ms (17.6 KiB/s)
Starts booting from SD
## Booting kernel from Legacy Image at a1000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    3969650 Bytes = 3.8 MiB
   Load Address: a0400000
   Entry Point:  a0400000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at a8300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    3588479 Bytes = 3.4 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at a8000000
   Booting using the fdt blob at 0xa8000000
   Uncompressing Kernel Image
   Using Device Tree in place at 00000000a8000000, end 00000000a8003f14

Starting kernel ...

[    0.000000] Linux version 5.10.0+ (hqfang@whss1.corp.nucleisys.com) (riscv-nuclei-linux-gnu-gcc (GCC) 9.2.0, GNU ld (GNU Binutils) 2.32) #10 SMP Mon Nov 22 18:32:26 CST 2021
[    0.000000] OF: fdt: Ignoring memory range 0xa0000000 - 0xa0400000
[    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
[    0.000000] printk: bootconsole [sbi0] enabled
[    0.000000] efi: UEFI not found.
[    0.000000] Initial ramdisk at: 0x(____ptrval____) (3592192 bytes)
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x00000000a0400000-0x00000000adffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x00000000a0400000-0x00000000adffffff]
[    0.000000] Initmem setup node 0 [mem 0x00000000a0400000-0x00000000adffffff]
[    0.000000] software IO TLB: mapped [mem 0x00000000a9cf7000-0x00000000adcf7000] (64MB)
[    0.000000] SBI specification v0.2 detected
[    0.000000] SBI implementation ID=0x1 Version=0x9
[    0.000000] SBI v0.2 TIME extension detected
[    0.000000] SBI v0.2 IPI extension detected
[    0.000000] SBI v0.2 RFENCE extension detected
[    0.000000] SBI v0.2 HSM extension detected
[    0.000000] riscv: ISA extensions acim
[    0.000000] riscv: ELF capabilities acim
[    0.000000] percpu: Embedded 16 pages/cpu s25112 r8192 d32232 u65536
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 55550
[    0.000000] Kernel command line: earlycon=sbi console=ttyNUC0
[    0.000000] Dentry cache hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    0.000000] Inode-cache hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    0.000000] Sorting __ex_table...
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Memory: 138748K/225280K available (4630K kernel code, 4236K rwdata, 2048K rodata, 188K init, 328K bss, 86532K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=4, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=8 to nr_cpu_ids=4.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=4
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped
[    0.000000] plic: interrupt-controller@8000000: mapped 53 interrupts with 4 handlers for 8 contexts.
[    0.000000] random: get_random_bytes called from 0xffffffe000002964 with crng_init=0
[    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000579] sched_clock: 64 bits at 32kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.014678] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.027160] pid_max: default: 32768 minimum: 301
[    0.049194] Mount-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.058044] Mountpoint-cache hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.228302] rcu: Hierarchical SRCU implementation.
[    0.256011] EFI services will not be available.
[    0.290679] smp: Bringing up secondary CPUs ...
[    1.470336] CPU1: failed to come online
[    2.653228] CPU2: failed to come online
[    3.837249] CPU3: failed to come online
[    3.845764] smp: Brought up 1 node, 1 CPU
[    3.887939] devtmpfs: initialized
[    4.040771] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    4.053253] futex hash table entries: 1024 (order: 4, 65536 bytes, linear)
[    4.076171] pinctrl core: initialized pinctrl subsystem
[    4.113983] NET: Registered protocol family 16
[    5.347015] clocksource: Switched to clocksource riscv_clocksource
[    5.471710] NET: Registered protocol family 2
[    5.541687] tcp_listen_portaddr_hash hash table entries: 256 (order: 0, 4096 bytes, linear)
[    5.553710] TCP established hash table entries: 2048 (order: 2, 16384 bytes, linear)
[    5.568603] TCP bind hash table entries: 2048 (order: 3, 32768 bytes, linear)
[    5.583312] TCP: Hash tables configured (established 2048 bind 2048)
[    5.607330] UDP hash table entries: 256 (order: 1, 8192 bytes, linear)
[    5.617980] UDP-Lite hash table entries: 256 (order: 1, 8192 bytes, linear)
[    5.642791] NET: Registered protocol family 1
[    5.702148] RPC: Registered named UNIX socket transport module.
[    5.709930] RPC: Registered udp transport module.
[    5.716430] RPC: Registered tcp transport module.
[    5.721679] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    5.756439] Trying to unpack rootfs image as initramfs...
[   24.337127] Freeing initrd memory: 3500K
[   24.405731] workingset: timestamp_bits=62 max_order=16 bucket_order=0
[   25.108306] jffs2: version 2.2. (NAND) ? 2001-2006 Red Hat, Inc.
[   25.171173] JFS: nTxBlock = 1111, nTxLock = 8890
[   30.998046] NET: Registered protocol family 38
[   31.003845] io scheduler mq-deadline registered
[   31.010955] io scheduler kyber registered
[   35.939666] 10013000.serial: ttyNUC0 at MMIO 0x10013000 (irq = 1, base_baud = 0) is a Nuclei UART/USART
[   35.952178] printk: console [ttyNUC0] enabled
[   35.952178] printk: console [ttyNUC0] enabled
[   35.962707] printk: bootconsole [sbi0] disabled
[   35.962707] printk: bootconsole [sbi0] disabled
[   37.080108] brd: module loaded
[   37.796142] loop: module loaded
[   37.829589] nuclei_spi 10014000.spi: mapped; irq=2, cs=1
[   37.911041] spi-nor spi0.0: gd25q32 (4096 Kbytes)
[   38.168762] random: fast init done
[   40.963745] ftl_cs: FTL header not found.
[   41.049835] nuclei_spi 10034000.spi: mapped; irq=4, cs=1
[   41.171173] libphy: Fixed MDIO Bus: probed
[   41.290649] mmc_spi spi1.0: SD/MMC host mmc0, no DMA, no WP, no poweroff, cd polling
[   41.335723] ipip: IPv4 and MPLS over IPv4 tunneling driver
[   41.440307] NET: Registered protocol family 10
[   41.578979] Segment Routing with IPv6
[   41.590179] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[   41.658477] NET: Registered protocol family 17
[   41.801025] Freeing unused kernel memory: 188K
[   41.809509] Run /init as init process
[   42.180999] mmc0: host does not support reading read-only switch, assuming write-enable
[   42.191345] mmc0: new SDHC card on SPI
[   42.358581] mmcblk0: mmc0:0000 SD08G 7.52 GiB
[   42.733947]  mmcblk0: p1 p2 p3 p4
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory
Saving random seed: [  143.897155] random: dd: uninitialized urandom read (512 bytes read)
OK

Welcome to Nuclei System Technology
nucleisys login: root
Password:
# cat /proc/cpuinfo
processor       : 0
hart            : 0
isa             : rv64imac
mmu             : sv39

# uname -a
Linux nucleisys 5.10.0+ #10 SMP Mon Nov 22 18:32:26 CST 2021 riscv64 GNU/Linux
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

The new configuration for demosoc will be saved to `conf/demosoc` folder, for when a full rebuild of buildroot
is necessary, please check [this link](https://buildroot.org/downloads/manual/manual.html#full-rebuild).

* *conf/demosoc/buildroot_initramfs_rv64imac_config*: The buildroot configuration for RISC-V ISA/ARCH is **rv64imac**, such as ux600 and ux900
* *conf/demosoc/buildroot_initramfs_rv64imafdc_config*: The buildroot configuration for for RISC-V ISA/ARCH is **rv64imafdc**, such as ux600fd and ux900fd

By default, we add many packages in buildroot default configuration, you can remove the packages
you dont need in configuration to generate smaller rootfs, a full rebuild of SDK is required for
removing buildroot package.

### Customize kernel configuration

You can customize linux kernel configuration using command `make linux-menuconfig`, the new configuration will be saved to `conf` folder

* *conf/demosoc/linux_rv64imac_defconfig*: The linux kernel configuration for RISC-V rv64imac ARCH.
* *conf/demosoc/linux_rv64imafdc_defconfig*: The linux kernel configuration for  RISC-V rv64imafdc ARCH.
* *conf/demosoc/nuclei_rv64imac.dts*: Device tree for RISC-V rv64imac ARCH used in hardware
* *conf/demosoc/nuclei_rv64imafdc.dts*: Device tree for RISC-V rv64imafdc ARCH used in hardware
* *conf/demosoc/nuclei_rv64imac_sim.dts*: Device tree for RISC-V rv64imac ARCH used in xlspike simulation
* *conf/demosoc/nuclei_rv64imafdc_sim.dts*: Device tree for RISC-V rv64imafdc ARCH used in xlspike simulation

### Customize uboot configuration

You can customize linux kernel configuration using command `make uboot-menuconfig`, the new configuration will be saved to `conf` folder

* *conf/demosoc/uboot_rv64imac_flash_config*: uboot configuration for RISC-V rv64imac ARCH, flash boot mode
* *conf/demosoc/uboot_rv64imafdc_flash_config*: uboot configuration for RISC-V rv64imafdc ARCH, flash boot mode
* *conf/demosoc/uboot_rv64imac_sd_config*: uboot configuration for RISC-V rv64imac ARCH, flash boot mode
* *conf/demosoc/uboot_rv64imafdc_sd_config*: uboot configuration for RISC-V rv64imafdc ARCH, sd boot mode

### Remove generated boot images

You can remove generated boot images using command `make cleanboot`.

### Prebuilt applications with RootFS

If you want to do application development in Linux with FPGA Evaluation board, please
follow these steps.

Currently, SDCard is not working in Linux, so if you want to put your own application, and run it in
linux, you have to add your application into rootfs and rebuild it, and use the newly generated boot
images, and put it into SDCard.

For example, I would like to compile new `dhrystone` application and run it in linux.

0. Make sure you have built boot images, using `make bootimages`

1. Copy the old `dhrystone` source code from `work/$SOC/buildroot_initramfs/build/dhrystone-2` to
   `work/$SOC/buildroot_initramfs/build/dhrystone-3`

2. cd to `work/$SOC/buildroot_initramfs/build/dhrystone-3`, and modify `Makefile` as below:

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

7. Download the generated `work/$SOC/boot.zip` and extract it right under the SDCard root.

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

## Port to your target

For our current development demo SoC, we used the following resources:

* RV64IMAC or RV64IMAFDC Core, with 16 PMP entries
* DDR RAM: *0xa0000000 - 0xb0000000*, DDR RAM is seperated to place opensbi, uboot, kernel, rootfs, dtb binaries.
* I/D Cache enabled
* UART @ 0x10013000
* GPIO @ 0x10012000
* Nuclei Core Timer @ 0x2000000, Timer Freqency @ 32768 Hz
* PLIC @ 0x8000000
* QSPI @ 0x10034000, which connect to SDCard, SDCard will be used when boot from SDCard
* QSPI @ 0x10014000, which connect to XIP SPIFlash 4M, memory mapped started at 0x20000000.

  SPIFlash is used to place freeloader, which contains opensbi, uboot, dtb, and optional kernel and rootfs
  when flash-only boot is performed. **Flash-only boot** will required at least 8M flash.

To basically port this SDK to match your target, you can make a copy of `conf/demosoc` such as `conf/nsoc`:

* *freeloader.mk*: change the variable defined in this mk to match your design
  * If you want to use SMP linux, you need to set **ENABLE_SMP** and **ENABLE_L2** to 1
  * If you only have 1 core, please make sure **ENABLE_SMP** and **ENABLE_L2** is 0
  * If you will not using amp mode, please set AMP_START_CORE to max hart id,
    for example, if you have four core, change it to 4.

* *build.mk*:
  * Change **UIMAGE_AE_CMD** to match your DDR base, used by Makefile to generate rootfs for uboot.
  * if you are using AMP, **CORE1_APP_BIN**, **CORE2_APP_BIN**, **CORE3_APP_BIN**, **CORE4_APP_BIN**,
    **CORE5_APP_BIN**, **CORE6_APP_BIN** and **CORE7_APP_BIN** need to be configured, CORE1-CORE7 each memory is 4MB
    and application base address is offset 0xE000000 at DDR base.
    > Here each core memory is changed from 8M to 4M, due to only 32MB is reserved for amp binaries, and now we support 8 cores.
  * **CORE1_APP_BIN** start offset is **DDR_BASE** + **0xE000000**, such as `$(confdir)/amp/c1.bin`
  * **CORE2_APP_BIN** start offset is **DDR_BASE** + **0xE000000** + **4M**, such as `$(confdir)/amp/c2.bin`
  * **CORE3_APP_BIN** start offset is **DDR_BASE** + **0xE000000** + **4M*2**, such as `$(confdir)/amp/c3.bin`
  * **CORE4_APP_BIN** start offset is **DDR_BASE** + **0xE000000** + **4M*3**, such as `$(confdir)/amp/c4.bin`
  * **CORE5_APP_BIN** start offset is **DDR_BASE** + **0xE000000** + **4M*4**, such as `$(confdir)/amp/c5.bin`
  * **CORE6_APP_BIN** start offset is **DDR_BASE** + **0xE000000** + **4M*5**, such as `$(confdir)/amp/c6.bin`
  * **CORE7_APP_BIN** start offset is **DDR_BASE** + **0xE000000** + **4M*6**, such as `$(confdir)/amp/c7.bin`

* *opensbi/*: Change the opensbi support code for your soc, all the files need to be modified.

* *nuclei_rv64imac.dts*, *nuclei_rv64imafdc.dts* and *openocd.cfg*: Change these files to match your SoC design.
  - External interrupts connected to plic interrupt number started from 1, 0 is reserved.
    For example, in demosoc, interrupt id of UART0 is 32, then plic interrupt number is 33,
    and if elic also present, the eclic interrupt number will be 32+19=51
  - If you want to boot linux using hvc console(console via sbi console, useful when uart driver in linux is not ready),
    you can change `bootargs` to make `console=/dev/hvc0`, then it will use sbi console to print message
  - If you UART driver is ready, then you can change the console to your real uart device name.

* *uboot.cmd*: Change to match your memory map.

* *uboot_rv64imac_sd_config*, *uboot_rv64imac_flash_config*, *uboot_rv64imafdc_sd_config* and *uboot_rv64imafdc_flash_config*:
  change **CONFIG_SYS_TEXT_BASE** and **CONFIG_BOOTCOMMAND** to match your uboot system text address and boot command address.

* If you have a lot of changes in uboot or linux, please directly change code in it.

> From commit 6507c68 on, the spmp will be bypassed(done in code as below) when tee is present(checked mcfg_info csr).
> If you have enabled TEE feature(sPMP module included), you need to configure spmp csr registers
> as this commit https://github.com/Nuclei-Software/opensbi/commit/1d28050d01b93b6afe590487324b663c65a2c429 .
> Then you will be able to boot up linux kernel, otherwise the init process will fail.

## Known issues and FAQs

* Clone source code from github or gitee failed with issue `the remote end hung up unexpectedly`.

  This Nuclei Linux SDK repo is a very big repo with many submodules, just simple clone is not enough, you always need to
  do submodule init and update, sometimes due to connection issue or http clone not stable issue, please switch to use ssh
  protocol used in git clone, see similar issue posted in stackoverflow, see https://stackoverflow.com/questions/6842687/the-remote-end-hung-up-unexpectedly-while-git-cloning

  Or you can try shallow submodule update:

  ~~~shell
  ## clone repo from github
  git clone https://github.com/Nuclei-Software/nuclei-linux-sdk.git
  ## if github is not working please use gitee
  # git clone https://gitee.com/Nuclei-Software/nuclei-linux-sdk.git
  ## if https is not ok, please switch to ssh method, but you need to follow guidance in github or gitee
  ## github: https://docs.github.com/cn/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent
  ## gitee: https://gitee.com/help/articles/4181
  cd nuclei-linux-sdk
  git submodule update --init --depth=1
  ## please check sample output here: https://github.com/Nuclei-Software/nuclei-linux-sdk/wiki/Sample-Outputs#sample-output-for-git-clone
  ~~~

  Or you just want to get latest source code without any git histories, you can also open our repo's github action link in github
  https://github.com/Nuclei-Software/nuclei-linux-sdk/actions , make sure your github is logged in, and then click on any successful
  action of your desired branch, and find the *nuclei_linux_sdk_source* in the **Artifacts** at the bottom of page, and click the
  *nuclei_linux_sdk_source* and download it.


* For Nuclei Demo SoC, if you run simulation using xl_spike, it can run to login prompt, but when you login, it will
  show timeout issue, this is caused by xl_spike timer is not standard type, but the boot images for FPGA evaluation
  board can boot successfully and works well.

  If you want to execute using `xl_spike` without the login, you can edit the *work/$SOC/buildroot_initramfs_sysroot/etc/inittab*
  file(started from `# now run any rc scripts`) as below, and save it:

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

* For some SDCard format, it might not be supported, please check your SDCard is SDHC format.

* If you can't boot with the sdcard boot images, you can run the following commands in uboot to check whether sdcard is recognized.

  1. Type `mmcinfo` to check whether sdcard is recognized? If no output, please re-insert the sdcard, and try
     this command again, if still not working, please confirm that the MCS is correct or not?

     ~~~
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
     are listed as below, if you can get the following files in your sdcard, please reformat your sdcard to `Fat32` format,
     and copy the generated files in *work/$SOC/boot/* to the root of sdcard, and re-insert the sdcard to SD slot, and retry from step 1.

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
     located in [./conf/demosoc/uboot.cmd](conf/demosoc/uboot.cmd).

* The linux kernel and rootfs size is too big, is there any way to reduce it to speed up boot speed?

  If you are familiar with linux and buildroot configuration files, you can directly modify the configuration
  files located in `conf` folder.

  If you modified this files directly and want to take effects, you need to `make clean` first, and regenerate
  boot images.

  You can also try `make buildroot_initramfs-menuconfig` to get a terminal menuconfig to configure the buildroot
  packages.

  You can also try `make linux-menuconfig` to get a menuconfig to configure the linux kernel.

  You can also try `make uboot-menuconfig` to get a menuconfig to configure the uboot.

* Other possible ways to reduce generated rootfs image size.

  If you are familiar with the generated rootfs files located in `work/buildroot_initramfs_sysroot`, you can
  manually remove the files you think it is not used, and type `make cleanboot` and then `make bootimages`,
  you can check the size information generated by the command.

* The best way to learn this project is taking a look at the [Makefile](Makefile) of this project to learn about
  what is really done in each make target.

* Download *work/$SOC/freeloader/freeloader.elf* using Nuclei SDK.

  If you don't want to build the nuclei sdk, you can also download the boot images generated by [github action](https://github.com/Nuclei-Software/nuclei-linux-sdk/actions).

  For example, for `dev_nuclei_next` branch, you can find the previous built artifacts in [prebuilt artifacts][1].

  Then you can extra the downloaded `bootimages_ux600.zip` and extract `freeloader/freeloader.elf` to your disk,
  such as `D:/freeloader.elf`.

  Make sure you have followed [steps](https://doc.nucleisys.com/nuclei_sdk/quickstart.html) to setup nuclei sdk
  development environment, then you can follow steps below to download this `D:/freeloader.elf`.

  ~~~
  D:\workspace\Sourcecode\nuclei-sdk>setup.bat
  Setup Nuclei SDK Tool Environment
  NUCLEI_TOOL_ROOT=D:\Software\NucleiStudio_IDE_202201\NucleiStudio\toolchain
  
  D:\workspace\Sourcecode\nuclei-sdk>make clean
  make -C application/baremetal/helloworld clean
  make[1]: Entering directory 'D:/workspace/Sourcecode/nuclei-sdk/application/baremetal/helloworld'
  "Clean all build objects"
  make[1]: Leaving directory 'D:/workspace/Sourcecode/nuclei-sdk/application/baremetal/helloworld'
  
  D:\workspace\Sourcecode\nuclei-sdk>make CORE=ux600 debug
  make -C application/baremetal/helloworld debug
  make[1]: Entering directory 'D:/workspace/Sourcecode/nuclei-sdk/application/baremetal/helloworld'
  .... ....
  "Compiling  : " ../../../SoC/demosoc/Common/Source/system_demosoc.c
  "Compiling  : " main.c
  "Linking    : " helloworld.elf
     text    data     bss     dec     hex filename
     8328     224    2492   11044    2b24 helloworld.elf
  "Download and debug helloworld.elf"
  riscv-nuclei-elf-gdb helloworld.elf -ex "set remotetimeout 240" \
          -ex "target remote | openocd --pipe -f ../../../SoC/demosoc/Board/nuclei_fpga_eval/openocd_demosoc.cfg"
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
  Remote debugging using | openocd --pipe -f ../../../SoC/demosoc/Board/nuclei_fpga_eval/openocd_demosoc.cfg
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

---

[1]: https://github.com/Nuclei-Software/nuclei-linux-sdk/actions/runs/2232759453

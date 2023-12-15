# Nuclei Linux SDK

[![Build and Test Linux SDK](https://github.com/Nuclei-Software/nuclei-linux-sdk/actions/workflows/build.yml/badge.svg?branch=dev_nuclei_6.1_v2)](https://github.com/Nuclei-Software/nuclei-linux-sdk/actions/workflows/build.yml)

[![Build Linux SDK Docker Image](https://github.com/Nuclei-Software/nuclei-linux-sdk/actions/workflows/docker.yml/badge.svg?branch=dev_nuclei_6.1_v2)](https://github.com/Nuclei-Software/nuclei-linux-sdk/actions/workflows/docker.yml)

Please check [about each branch feature](https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/2) to learn which branch you should choose.

## Tested Configurations

### Docker

If you want to use it in docker image, please follow steps below:

> Not tested for upload freeloader, need USB connection.

See [How to evaluate Nuclei Linux SDK in docker](https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/8)

### Ubuntu 20.04 x86_64 host

- Status: Working
- Build dependencies
  - packages: see [apt.txt](.github/apt.txt)
  - python pip packages: [pipreq.txt](.github/pipreq.txt)
- Get prebuilt qemu and openocd 2023.10 from [Nuclei Development Tools](https://nucleisys.com/download.php#tools)
- Setup qemu and openocd and add it into **PATH**
- mtools version >= 4.0.24

## Build Instructions

### Install Dependencies

Install the software dependencies required by this SDK using command:

~~~shell
sudo xargs apt-get install -y < .github/apt.txt
sudo pip3 install -r .github/pipreq.txt
~~~

### Install Nuclei Tools

Download prebuilt 64bit `openocd` tool and `qemu` from [Nuclei Development Tools](https://nucleisys.com/download.php#tools),
and extract it into your PC, and then setup **PATH** using this command:

> \>= 2023.10 release is required. You can install Nuclei Studio, which contains prebuilt openocd/qemu

~~~shell
# Make sure you changed /path/to/openocd/bin and /path/to/qemu/bin to the real path of your PC
export PATH=/path/to/openocd/bin:/path/to/qemu/bin:$PATH
# Check path is set correctly
which openocd qemu-system-riscv64
~~~

### Fix nuclei riscv gdb run issue

You may meet with this issue: `error while loading shared libraries: libgmp.so.3: cannot open shared object file: No such file or directory`

~~~
# see issue https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/5
sudo ln -s /lib/x86_64-linux-gnu/libgmp.so /lib/x86_64-linux-gnu/libgmp.so.3
~~~

If you met other strange issues not documented in this doc,
please check [Linux SDK Issues](https://github.com/Nuclei-Software/nuclei-linux-sdk/issues), if the
existing issues not address your problem, please [create a new issue](https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/new)

### Clone Repo

> **Gitee Mirror not longer work**, since linux mirror repo is blocked by gitee, see https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/10#issuecomment-1728920670

* Checkout this repository using `git`.

> Change the below `dev_nuclei_6.1_v2` to your desired branch.

  - If you have good network access to github, you can clone this repo using command
    `git clone -b dev_nuclei_6.1_v2 https://github.com/Nuclei-Software/nuclei-linux-sdk`
  - Otherwise, you can try methods provided https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/10
  - If https is not stable, you can try ssh, please search about git clone ssh/https difference

* Then you will need to checkout all of the linked submodules using:

  ~~~shell
  cd nuclei-linux-sdk
  # the following command might fail due to network connection issue
  # you can clone less code with --depth=1
  # you can also try some github mirror tech, search in baidu/google
  # if still not working, you can try our prepared source code(maybe out of date), see https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/4
  git submodule update --recursive --init
  # if you want to clone less source code to speed up or make clone stable, please add extra --depth=1
  # --depth=1 is used to do shallow clone, see https://git-scm.com/docs/git-submodule#Documentation/git-submodule.txt---depth
  # git submodule update --init --depth=1
  ~~~

* To make sure you have checked out clean source code, you need to run `git status` command,
  and get expected output as below:

  ~~~
  On branch dev_nuclei_6.1_v2
  Your branch is up to date with 'origin/dev_nuclei_6.1_v2'.

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

Assume currently you are in `dev_nuclei_6.1_v2` branch, and the working tree is clean.

Then you run the following command to update this repo:

~~~shell
# Pull lastest source code and rebase your local commits onto it
git pull --rebase origin dev_nuclei_6.1_v2
# Update git submodules
git submodule update
# Check workspace status to see whether it is clean
git status
~~~

### Switch branch

See https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/10

## Show Help

You can run `make help` to show help message about how to use this Nuclei Linux SDK.

But if you want to change and adapt for your SoC, you need to understand the build system in Makefile.

## Nuclei Linux SDK Integration

Here are the version numbers of sub projects used in Nuclei Linux SDK.

* Linux 6.6.y
* Uboot v2023.10
* OpenSBI master >= v1.3.1
* Buildroot 2023.08.4

Our changes to support Nuclei Eval SoC are adapted based on above version.

## Modify Build Configuration

You can choose different core configuration by modify the `CORE ?= ux900fd` line in `Makefile`.

We support four configurations for **CORE**, choose the right core according to your configuration:

* `ux600` or `ux900`: rv64imac RISC-V CORE configuration without FPU.
* `ux600fd` or `ux900fd`: rv64imafdc RISC-V CORE configuration with FPU.
* `u900`: rv32imac RISC-V CORE configuration without FPU added from 2023.06.
* `u900fd`: rv32imafdc RISC-V CORE configuration with FPU added from 2023.06.

You can choose different SoC by modify `SOC ?= evalsoc` line in `Makefile`.

* `evalsoc`: The next generation of the `demosoc`, we call it `evalsoc`, when your cpu has `iregion` feature, please use this one
* you can add your SoC support by adding configuration in `conf/$SOC` folder refer to `conf/evalsoc`

> You can check the dts difference for evalsoc, for more details, need to check the Nuclei RISC-V CPU ISA spec.

> **demosoc** support is removed

> - Default SoC changed to evalsoc, and default CORE changed to ux900fd from 2023.06
> - Now evalsoc default cpu/peripheral frequency change from 100M to 50MHz from 2023.06
> - From 2023.06, evalsoc ddr base address changed from 0xA0000000 to 0x80000000, so previous release of 600 and 900 bitstream may not work on this sdk, please take care

You can choose different boot mode by modify the `BOOT_MODE ?= sd` line in `Makefile`.

* `sd`: boot from flash + sdcard, extra SDCard is required(kernel, rootfs, dtb placed in it)
* `flash`: boot from flash only, flash will contain images placed in sdcard of sd boot mode, at least 8M flash is required, current onboard mcu-flash of DDR200T is only 4M, so this feature is not ready for it.

Please modify the `Makefile` to your correct core configuration before build any source code.

For each SoC, in `conf/$SOC/`, it contains a `build.mk` you can specify qemu, timer/cpu/peripheral hz.

* **TIMER_HZ**: implementation dependent, you can change timer frequency to different value to overwrite the one in dts.
* **CPU_HZ**: implementation dependent, you can change cpu frequency to different value to overwrite the one in dts.
* **PERIPH_HZ**: implementation dependent, you can change peripheral frequency to different value to overwrite the one in dts.
* **SIMULATION**: implementation dependent, if SIMULATION=1, only the peripherals can be simulated in rtl will be present in dts, for evalsoc, only uart will be present, qspi will not.

> `TIMER_HZ/CPU_HZ/PERIPH_HZ` are all implementation dependent, it required your SoC dts implement this feature, currently
> evalsoc support this.

For each SoC, in `conf/$SOC`, it also contains a `freeloader.mk`, it is used to configure freeloader feature to set cpu configuration when bring up, such as configure cache, tlb, smp feature, for details, please refer to freeloader source code.

* **Deprecated**: If you want to compile and run using simulator *xl-spike*, please
  check steps mentioned in [Booting Linux on Nuclei xl-spike](#Booting-Linux-on-Nuclei-xl-spike)
* If you want to compile and run using FPGA evaluation board, please
  check steps mentioned in [Booting Linux on Nuclei FPGA Evaluation Board](#Booting-Linux-on-Nuclei-FPGA-Evaluation-Board)

## Booting Linux on Nuclei xl-spike

**Note**: `xl_spike` tool should be installed and added into **PATH** in advance.
Contact with our sales via email **contact@nucleisys.com** to get `xl_spike` tools.

> This feature is **deprecated** now, please use Nuclei Qemu.

### Run on xl_spike

If you have run `make bootimages` command before, please make sure you run `make presim` to prepare
build environment for running linux in simulation.

When toolchain steps are finished, then, you can build buildroot, linux and opensbi,
and run opensbi with linux payload on xlspike by running `make sim`.

Here is sample output running in xl_spike:

> Log is not up to date, and may not working.

~~~
xl_spike --isa=rv64imac /home/hqfang/workspace/software/nuclei-linux-sdk/work/evalsoc/opensbi/platform/generic/firmware/fw_payload.elf
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

> From 2023.06, this branch will no longer work with Nuclei QEMU 2022.12 release, please take a try with Nuclei Qemu 2023.10 release.

**Note**: `qemu-system-riscv64` tool should be installed and added into **PATH** in advance.

When the required changes has been done, then you can run `make run_qemu` to run riscv linux on Nuclei QEMU, here are the sample output.

> You can check latest output in github action https://github.com/Nuclei-Software/nuclei-linux-sdk/actions/workflows/build.yml?query=branch%3Adev_nuclei_6.1_v2

> This may be out of date.

~~~
Run on qemu for simulation
qemu-system-riscv64 -M nuclei_evalsoc,download=flashxip -smp 8 -m 2G -cpu nuclei-ux900fd,ext= -bios /Local/hqfang/workspace/software/nuclei-linux-sdk/work/evalsoc/freeloader/freeloader.elf -nographic -drive file=/Local/hqfang/workspace/software/nuclei-linux-sdk/work/evalsoc/disk.img,if=sd,format=raw

OpenSBI v1.3
Build time: 2023-11-20 14:52:35 +0800
Build compiler: gcc version 10.2.0 (GCC)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|___/_____|
        | |
        |_|

Platform Name             : nuclei,evalsoc
Platform Features         : medeleg
Platform HART Count       : 8
Platform IPI Device       : aclint-mswi
Platform Timer Device     : aclint-mtimer @ 32768Hz
Platform Console Device   : nuclei_uart
Platform HSM Device       : ---
Platform PMU Device       : ---
Platform Reboot Device    : ---
Platform Shutdown Device  : ---
Platform Suspend Device   : ---
Platform CPPC Device      : ---
Firmware Base             : 0x80000000
Firmware Size             : 264 KB
Firmware RW Offset        : 0x20000
Firmware RW Size          : 136 KB
Firmware Heap Offset      : 0x36000
Firmware Heap Size        : 48 KB (total), 3 KB (reserved), 9 KB (used), 35 KB (free)
Firmware Scratch Size     : 4096 B (total), 760 B (used), 3336 B (free)
Runtime SBI Version       : 1.0

Domain0 Name              : root
Domain0 Boot HART         : 1
Domain0 HARTs             : 0*,1*,2*,3*,4*,5*,6*,7*
Domain0 Region00          : 0x0000000018031000-0x0000000018031fff M: (I,R,W) S/U: ()
Domain0 Region01          : 0x000000001803c000-0x000000001803cfff M: (I,R,W) S/U: ()
Domain0 Region02          : 0x0000000018032000-0x0000000018033fff M: (I,R,W) S/U: ()
Domain0 Region03          : 0x0000000018034000-0x0000000018037fff M: (I,R,W) S/U: ()
Domain0 Region04          : 0x0000000018038000-0x000000001803bfff M: (I,R,W) S/U: ()
Domain0 Region05          : 0x0000000080000000-0x000000008001ffff M: (R,X) S/U: ()
Domain0 Region06          : 0x0000000080000000-0x000000008007ffff M: (R,W) S/U: ()
Domain0 Region07          : 0x0000000000000000-0xffffffffffffffff M: (R,W,X) S/U: (R,W,X)
Domain0 Next Address      : 0x0000000080200000
Domain0 Next Arg1         : 0x0000000088000000
Domain0 Next Mode         : S-mode
Domain0 SysReset          : yes
Domain0 SysSuspend        : yes

Boot HART ID              : 1
Boot HART Domain          : root
Boot HART Priv Version    : v1.12
Boot HART Base ISA        : rv64imafdc
Boot HART ISA Extensions  : time
Boot HART PMP Count       : 16
Boot HART PMP Granularity : 4
Boot HART PMP Address Bits: 54
Boot HART MHPM Count      : 29
Boot HART MIDELEG         : 0x0000000000000222
Boot HART MEDELEG         : 0x000000000000b109


U-Boot 2023.01-00007-g2ffa69c07f (Nov 20 2023 - 14:52:21 +0800)

CPU:   rv64imafdc
Model: nuclei,evalsoc
DRAM:  2 GiB
Board: Initialized
Core:  24 devices, 13 uclasses, devicetree: board
MMC:   Nuclei SPI version 0x0
spi@10034000:mmc@0: 0
Loading Environment from nowhere... OK
In:    serial@10013000
Out:   serial@10013000
Err:   serial@10013000
Net:   No ethernet found.
Hit any key to stop autoboot:  0
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
725 bytes read in 24 ms (29.3 KiB/s)
## Executing script at 80200000
Boot images located in .
Loading kernel: ./uImage.lz4
4078392 bytes read in 10272 ms (387.7 KiB/s)
Loading ramdisk: ./uInitrd.lz4
6261560 bytes read in 15902 ms (383.8 KiB/s)
Loading dtb: ./kernel.dtb
4677 bytes read in 31 ms (146.5 KiB/s)
Starts booting from SD
## Booting kernel from Legacy Image at 83000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    4078328 Bytes = 3.9 MiB
   Load Address: 80400000
   Entry Point:  80400000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at 88300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    6261496 Bytes = 6 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at 88000000
   Booting using the fdt blob at 0x88000000
Working FDT set to 88000000
   Uncompressing Kernel Image
   Using Device Tree in place at 0000000088000000, end 0000000088004244
Working FDT set to 88000000

Starting kernel ...

[    0.000000] Linux version 6.1.54+ (hqfang@whss5.corp.nucleisys.com) (riscv-nuclei-linux-gnu-gcc (GCC) 10.2.0, GNU ld (GNU Binutils) 2.36.1) #1 SMP Mon Nov 20 14:26:00 CST 2023
[    0.000000] OF: fdt: Ignoring memory range 0x80000000 - 0x80400000
[    0.000000] Machine model: nuclei,evalsoc
[    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
[    0.000000] printk: bootconsole [sbi0] enabled
[    0.000000] efi: UEFI not found.
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000080400000-0x00000000fdffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000080400000-0x00000000fdffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000080400000-0x00000000fdffffff]
[    0.000000] SBI specification v1.0 detected
[    0.000000] SBI implementation ID=0x1 Version=0x10003
[    0.000000] SBI TIME extension detected
[    0.000000] SBI IPI extension detected
[    0.000000] SBI RFENCE extension detected
[    0.000000] SBI HSM extension detected
[    0.000000] riscv: base ISA extensions acdfim
[    0.000000] riscv: ELF capabilities acdfim
[    0.000000] percpu: Embedded 15 pages/cpu s22504 r8192 d30744 u61440
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 508030
[    0.000000] Kernel command line: earlycon=sbi console=ttyNUC0
[    0.000000] Dentry cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] Inode-cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Memory: 2005992K/2060288K available (4770K kernel code, 4741K rwdata, 2048K rodata, 2123K init, 315K bss, 54296K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=8, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=64 to nr_cpu_ids=8.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=8
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped
[    0.000000] plic: interrupt-controller@1c000000: mapped 53 interrupts with 8 handlers for 16 contexts.
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] riscv-timer: riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [1]
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000091] sched_clock: 64 bits at 33kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.005035] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.005676] pid_max: default: 32768 minimum: 301
[    0.009063] Mount-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.009490] Mountpoint-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.040496] riscv: ELF compat mode supported
[    0.040802] ASID allocator using 16 bits (65536 entries)
[    0.041961] rcu: Hierarchical SRCU implementation.
[    0.042327] rcu:     Max phase no-delay instances is 1000.
[    0.043975] EFI services will not be available.
[    0.045867] smp: Bringing up secondary CPUs ...
[    0.071014] smp: Brought up 1 node, 8 CPUs
[    0.098541] devtmpfs: initialized
[    0.110412] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.111480] futex hash table entries: 2048 (order: 5, 131072 bytes, linear)
[    0.112701] pinctrl core: initialized pinctrl subsystem
[    0.119750] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.163391] pps_core: LinuxPPS API ver. 1 registered
[    0.163818] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.164581] PTP clock support registered
[    0.177825] clocksource: Switched to clocksource riscv_clocksource
[    0.191223] NET: Registered PF_INET protocol family
[    0.195068] IP idents hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    0.201660] tcp_listen_portaddr_hash hash table entries: 1024 (order: 2, 16384 bytes, linear)
[    0.202148] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.202575] TCP established hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    0.203216] TCP bind hash table entries: 16384 (order: 7, 524288 bytes, linear)
[    0.203918] TCP: Hash tables configured (established 16384 bind 16384)
[    0.205780] UDP hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    0.206390] UDP-Lite hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    0.208923] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    0.216949] Trying to unpack rootfs image as initramfs...
[    0.320800] workingset: timestamp_bits=62 max_order=19 bucket_order=0
[    0.338134] jffs2: version 2.2. (NAND) © 2001-2006 Red Hat, Inc.
[    0.340637] JFS: nTxBlock = 8192, nTxLock = 65536
[    0.351348] jitterentropy: Initialization failed with host not compliant with requirements: 2
[    0.352478] io scheduler mq-deadline registered
[    0.352783] io scheduler kyber registered
[    0.486785] 10013000.serial: ttyNUC0 at MMIO 0x10013000 (irq = 1, base_baud = 3125000) is a Nuclei UART v0
[    0.488891] printk: console [ttyNUC0] enabled
[    0.488891] printk: console [ttyNUC0] enabled
[    0.489654] printk: bootconsole [sbi0] disabled
[    0.489654] printk: bootconsole [sbi0] disabled
[    0.519592] brd: module loaded
[    0.529937] Freeing initrd memory: 6108K
[    0.531005] loop: module loaded
[    0.534942] nuclei_spi 10014000.spi: mapped; irq=2, cs=1
[    0.545257] spi-nor spi0.0: is25wp256 (32768 Kbytes)
[    0.877471] ftl_cs: FTL header not found.
[    0.886016] nuclei_spi 10034000.spi: mapped; irq=3, cs=1
[    0.932220] mmc_spi spi1.0: SD/MMC host mmc0, no DMA, no WP, no poweroff, cd polling
[    0.940765] NET: Registered PF_INET6 protocol family
[    0.962127] Segment Routing with IPv6
[    0.963256] In-situ OAM (IOAM) with IPv6
[    0.965118] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[    0.969909] NET: Registered PF_PACKET protocol family
[    0.999481] mmc0: host does not support reading read-only switch, assuming write-enable
[    1.000091] mmc0: new SD card on SPI
[    1.011077] mmcblk0: mmc0:0000 QEMU! 1.00 GiB
[    1.017272] Freeing unused kernel image (initmem) memory: 2120K
[    1.041381]  mmcblk0: p1
[    1.060028] Run /init as init process
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory
Saving random seed: [    5.347137] random: dd: uninitialized urandom read (32 bytes read)
OK

Welcome to Nuclei System Technology
nucleisys login: root
Password:
# cat /proc/cpuinfo
processor       : 0
hart            : 1
isa             : rv64imafdc
mmu             : sv57
mvendorid       : 0x0
marchid         : 0x80000
mimpid          : 0x80000

processor       : 1
hart            : 0
isa             : rv64imafdc
mmu             : sv57
mvendorid       : 0x0
marchid         : 0x80000
mimpid          : 0x80000

processor       : 2
hart            : 2
isa             : rv64imafdc
mmu             : sv57
mvendorid       : 0x0
marchid         : 0x80000
mimpid          : 0x80000

processor       : 3
hart            : 3
isa             : rv64imafdc
mmu             : sv57
mvendorid       : 0x0
marchid         : 0x80000
mimpid          : 0x80000

processor       : 4
hart            : 4
isa             : rv64imafdc
mmu             : sv57
mvendorid       : 0x0
marchid         : 0x80000
mimpid          : 0x80000

processor       : 5
hart            : 5
isa             : rv64imafdc
mmu             : sv57
mvendorid       : 0x0
marchid         : 0x80000
mimpid          : 0x80000

processor       : 6
hart            : 6
isa             : rv64imafdc
mmu             : sv57
mvendorid       : 0x0
marchid         : 0x80000
mimpid          : 0x80000

processor       : 7
hart            : 7
isa             : rv64imafdc
mmu             : sv57
mvendorid       : 0x0
marchid         : 0x80000
mimpid          : 0x80000

# uname -a
Linux nucleisys 6.1.54+ #1 SMP Mon Nov 20 14:26:00 CST 2023 riscv64 GNU/Linux
# free -m
              total        used        free      shared  buff/cache   available
Mem:           1967          27        1919          14          22        1913
Swap:             0           0           0
# mount /dev/mmcblk0p1 /mnt/
# ls /mnt/
boot.scr     kernel.dtb   uImage.lz4   uInitrd.lz4
~~~

## Booting Linux on Nuclei FPGA Evaluation Board

### Get Nuclei Eval SoC FPGA Bitstream from Nuclei

> Demo SoC is deprecated, please use Eval SoC bitstream from Nuclei.

Contact with our sales via email **contact@nucleisys.com** to get FPGA bitstream for Nuclei
Eval SoC and get guidance about how to program FPGA bitstream in the board.

Nuclei Eval SoC can be configured using Nuclei RISC-V Linux Capable Core such as UX600 and U900/UX900,
To learn about Nuclei RISC-V Linux Capable Core, please check:

* [UX600 Series 64-Bit High Performance Application Processor](https://nucleisys.com/product/600.php)
* [900 Series 32/64-Bit High Performance Processor](https://nucleisys.com/product/900.php)

Nuclei FPGA Evaluation Board, DDR200T/KU060/VCU118 are correct hardwares to
run linux on it, click [Nuclei FPGA Evaluation Board](https://nucleisys.com/developboard.php#ddr200t) to learn about more.

### Apply changes for your SoC

Before compiling this source code, please make sure you have done the following changes.

Now we have two version of SoC for customer to evaluate our RISC-V CPU IP, if the bitstream you get from us
has the `iregion` feature, you should use `evalsoc`, otherwise choose `demosoc`(deprecated and removed).

If there is double float fpu and isa is rv64 in the bitstream supported, you should choose `ux600fd` or `ux900fd`.

- Removed now, default cpu/periph freq and timer freq are 16MHz and 32768Hz for demosoc.
- Default cpu/periph freq and timer freq are 50Mhz and 32768Hz for evalsoc v2.

About detailed SoC information, please check https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/2

If the bitstream you get not matching above settings, please change co-reponsibing `conf/<SOC>/build.mk`'s `TIMER_HZ`/`CPU_HZ`/`PERIPH_HZ`.

If you don't change this `build.mk` you can also change the dts files `conf/<SOC>/*.dts` to match the correct frequency.

For example, you have get a bitstream which is our ux900 series cpu ip, with double float fpu, and cpu frequency is 100MHz.

You should change `SOC` to `evalsoc`, `CORE` to `ux900fd` in [Makefile](Makefile).

And change `CPU_HZ` in `conf/<SOC>/build.mk` or **CPUCLK_FREQ** in the `nuclei_rv64imafdc.dts` and `nuclei_rv64imac.dts`
in `conf/$SOC/`(`conf/evalsoc` for this case).

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
* **boot.scr**    : required, boot script used by uboot, generated from [./conf/evalsoc/uboot.cmd](conf/evalsoc/uboot.cmd)
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
> changed from 8MHz to 16MHz or 50MHz, and now uart can work correctly on 115200bps.

> This may be out of date.

~~~
OpenSBI v1.3
Build time: 2023-11-20 14:58:03 +0800
Build compiler: gcc version 10.2.0 (GCC)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|___/_____|
        | |
        |_|

Platform Name             : nuclei,evalsoc
Platform Features         : medeleg
Platform HART Count       : 8
Platform IPI Device       : aclint-mswi
Platform Timer Device     : aclint-mtimer @ 32768Hz
Platform Console Device   : nuclei_uart
Platform HSM Device       : ---
Platform PMU Device       : ---
Platform Reboot Device    : ---
Platform Shutdown Device  : ---
Platform Suspend Device   : ---
Platform CPPC Device      : ---
Firmware Base             : 0x80000000
Firmware Size             : 264 KB
Firmware RW Offset        : 0x20000
Firmware RW Size          : 136 KB
Firmware Heap Offset      : 0x36000
Firmware Heap Size        : 48 KB (total), 3 KB (reserved), 9 KB (used), 35 KB (free)
Firmware Scratch Size     : 4096 B (total), 760 B (used), 3336 B (free)
Runtime SBI Version       : 1.0

Domain0 Name              : root
Domain0 Boot HART         : 0
Domain0 HARTs             : 0*,1*,2*,3*,4*,5*,6*,7*
Domain0 Region00          : 0x0000000018031000-0x0000000018031fff M: (I,R,W) S/U: ()
Domain0 Region01          : 0x000000001803c000-0x000000001803cfff M: (I,R,W) S/U: ()
Domain0 Region02          : 0x0000000018032000-0x0000000018033fff M: (I,R,W) S/U: ()
Domain0 Region03          : 0x0000000018034000-0x0000000018037fff M: (I,R,W) S/U: ()
Domain0 Region04          : 0x0000000018038000-0x000000001803bfff M: (I,R,W) S/U: ()
Domain0 Region05          : 0x0000000080000000-0x000000008001ffff M: (R,X) S/U: ()
Domain0 Region06          : 0x0000000080000000-0x000000008007ffff M: (R,W) S/U: ()
Domain0 Region07          : 0x0000000000000000-0xffffffffffffffff M: (R,W,X) S/U: (R,W,X)
Domain0 Next Address      : 0x0000000080200000
Domain0 Next Arg1         : 0x0000000088000000
Domain0 Next Mode         : S-mode
Domain0 SysReset          : yes
Domain0 SysSuspend        : yes

Boot HART ID              : 0
Boot HART Domain          : root
Boot HART Priv Version    : v1.12
Boot HART Base ISA        : rv64imafdcb
Boot HART ISA Extensions  : sscofpmf,time,sstc
Boot HART PMP Count       : 8
Boot HART PMP Granularity : 4096
Boot HART PMP Address Bits: 30
Boot HART MHPM Count      : 4
Boot HART MIDELEG         : 0x0000000000002222
Boot HART MEDELEG         : 0x000000000000b109


U-Boot 2023.01-00007-g2ffa69c07f (Nov 20 2023 - 14:58:00 +0800)

CPU:   rv64imafdc
Model: nuclei,evalsoc
DRAM:  2 GiB
Board: Initialized
Core:  24 devices, 13 uclasses, devicetree: board
MMC:   Nuclei SPI version 0xee010102
spi@10034000:mmc@0: 0
Loading Environment from nowhere... OK
In:    serial@10013000
Out:   serial@10013000
Err:   serial@10013000
Net:   No ethernet found.
Hit any key to stop autoboot:  0
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
725 bytes read in 361 ms (2 KiB/s)
## Executing script at 80200000
Boot images located in ./
Loading kernel: ./uImage.lz4
4072711 bytes read in 21702 ms (182.6 KiB/s)
Loading ramdisk: ./uInitrd.lz4
6261677 bytes read in 32974 ms (184.6 KiB/s)
6.1_rv64/kernel.dtb not found, ignore it
Starts booting from SD
## Booting kernel from Legacy Image at 81000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    4072647 Bytes = 3.9 MiB
   Load Address: 80400000
   Entry Point:  80400000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at 88300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    6261613 Bytes = 6 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at 88000000
   Booting using the fdt blob at 0x88000000
Working FDT set to 88000000
   Uncompressing Kernel Image
   Using Device Tree in place at 0000000088000000, end 0000000088004664
Working FDT set to 88000000

Starting kernel ...

[    0.000000] Linux version 6.1.31+ (xl_ci@whml1.corp.nucleisys.com) (riscv-nuclei-linux-gnu-gcc (GCC) 10.2.0, GNU ld (GNU Binutils) 2.36.1) #1 SMP Fri Jun3
[    0.000000] OF: fdt: Ignoring memory range 0x80000000 - 0x80400000
[    0.000000] Machine model: nuclei,evalsoc
[    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
[    0.000000] printk: bootconsole [sbi0] enabled
[    0.000000] efi: UEFI not found.
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000080400000-0x00000000fdffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000080400000-0x00000000fdffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000080400000-0x00000000fdffffff]
[    0.000000] SBI specification v1.0 detected
[    0.000000] SBI implementation ID=0x1 Version=0x10003
[    0.000000] SBI TIME extension detected
[    0.000000] SBI IPI extension detected
[    0.000000] SBI RFENCE extension detected
[    0.000000] SBI HSM extension detected
[    0.000000] riscv: base ISA extensions acdfim
[    0.000000] riscv: ELF capabilities acdfim
[    0.000000] percpu: Embedded 15 pages/cpu s22504 r8192 d30744 u61440
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 508030
[    0.000000] Kernel command line: earlycon=sbi console=ttyNUC0
[    0.000000] Dentry cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] Inode-cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Memory: 2006008K/2060288K available (4763K kernel code, 4741K rwdata, 2048K rodata, 2123K init, 315K bss, 54280K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=8, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=64 to nr_cpu_ids=8.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=8
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped
[    0.000000] plic: interrupt-controller@1c000000: mapped 53 interrupts with 8 handlers for 16 contexts.
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] riscv-timer: riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000000] sched_clock: 64 bits at 33kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.010314] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.020172] pid_max: default: 32768 minimum: 301
[    0.028259] Mount-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.036376] Mountpoint-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.076202] riscv: ELF compat mode supported
[    0.076660] ASID allocator using 16 bits (65536 entries)
[    0.088226] rcu: Hierarchical SRCU implementation.
[    0.092498] rcu:     Max phase no-delay instances is 1000.
[    0.102172] EFI services will not be available.
[    0.118591] smp: Bringing up secondary CPUs ...
[    0.236480] smp: Brought up 1 node, 8 CPUs
[    0.251556] devtmpfs: initialized
[    0.277801] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.287597] futex hash table entries: 2048 (order: 5, 131072 bytes, linear)
[    0.299468] pinctrl core: initialized pinctrl subsystem
[    0.317932] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.413909] pps_core: LinuxPPS API ver. 1 registered
[    0.418365] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.428192] PTP clock support registered
[    0.442047] clocksource: Switched to clocksource riscv_clocksource
[    0.467498] NET: Registered PF_INET protocol family
[    0.482391] IP idents hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    0.550506] tcp_listen_portaddr_hash hash table entries: 1024 (order: 2, 16384 bytes, linear)
[    0.559692] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.567291] TCP established hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    0.580841] TCP bind hash table entries: 16384 (order: 7, 524288 bytes, linear)
[    0.609100] TCP: Hash tables configured (established 16384 bind 16384)
[    0.620452] UDP hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    0.628540] UDP-Lite hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    0.639434] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    0.657897] Trying to unpack rootfs image as initramfs...
[    0.678283] workingset: timestamp_bits=62 max_order=19 bucket_order=0
[    0.759002] jffs2: version 2.2. (NAND)  2001-2006 Red Hat, Inc.
[    0.771484] JFS: nTxBlock = 8192, nTxLock = 65536
[    2.307800] io scheduler mq-deadline registered
[    2.312103] io scheduler kyber registered
[    3.240692] 10013000.serial: ttyNUC0 at MMIO 0x10013000 (irq = 1, base_baud = 3125000) is a Nuclei UART v0
[    3.250427] printk: console [ttyNUC0] enabled
[    3.250427] printk: console [ttyNUC0] enabled
[    3.258697] printk: bootconsole [sbi0] disabled
[    3.258697] printk: bootconsole [sbi0] disabled
[    3.400177] brd: module loaded
[    3.492095] loop: module loaded
[    3.499877] nuclei_spi 10014000.spi: mapped; irq=2, cs=4
[    3.515777] spi-nor spi0.0: w25q128 (16384 Kbytes)
[    4.300811] ftl_cs: FTL header not found.
[    4.321197] nuclei_spi 10034000.spi: mapped; irq=3, cs=4
[    4.372711] mmc_spi spi1.0: SD/MMC host mmc0, no DMA, no WP, no poweroff, cd polling
[    4.395629] NET: Registered PF_INET6 protocol family
[    4.423461] Segment Routing with IPv6
[    4.427307] In-situ OAM (IOAM) with IPv6
[    4.432067] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[    4.446807] NET: Registered PF_PACKET protocol family
[    4.556854] mmc0: host does not support reading read-only switch, assuming write-enable
[    4.564575] mmc0: new SDHC card on SPI
[    4.584777] mmcblk0: mmc0:0000 SD32G 29.7 GiB
[    4.640350]  mmcblk0: p1
[    5.488067] Freeing initrd memory: 6108K
[    5.570770] Freeing unused kernel image (initmem) memory: 2120K
[    5.577270] Run /init as init process
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory
Saving random seed: [   13.221099] random: dd: uninitialized urandom read (32 bytes read)
OK

Welcome to Nuclei System Technology
nucleisys login: root
Password:
# uname -a
Linux nucleisys 6.1.31+ #1 SMP Fri Jun  9 17:48:59 CST 2023 riscv64 GNU/Linux
# free -m
              total        used        free      shared  buff/cache   available
Mem:           1967          27        1919          14          22        1913
Swap:             0           0           0
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

The new configuration for evalsoc will be saved to `conf/evalsoc` folder, for when a full rebuild of buildroot
is necessary, please check [this link](https://buildroot.org/downloads/manual/manual.html#full-rebuild).

* *conf/evalsoc/buildroot_initramfs_rv64imac_config*: The buildroot configuration for RISC-V ISA/ARCH is **rv64imac**, such as ux600 and ux900
* *conf/evalsoc/buildroot_initramfs_rv64imafdc_config*: The buildroot configuration for for RISC-V ISA/ARCH is **rv64imafdc**, such as ux600fd and ux900fd
* *conf/evalsoc/buildroot_initramfs_rv32imac_config*: The buildroot configuration for RISC-V ISA/ARCH is **rv32imac**, such as u900
* *conf/evalsoc/buildroot_initramfs_rv32imafdc_config*: The buildroot configuration for for RISC-V ISA/ARCH is **rv32imafdc**, such as u900fd

By default, we add many packages in buildroot default configuration, you can remove the packages
you dont need in configuration to generate smaller rootfs, a full rebuild of SDK is required for
removing buildroot package.

### Customize kernel configuration

You can customize linux kernel configuration using command `make linux-menuconfig`, the new configuration will be saved to `conf` folder

* *conf/evalsoc/linux_rv64imac_defconfig*: The linux kernel configuration for RISC-V rv64imac ARCH.
* *conf/evalsoc/linux_rv64imafdc_defconfig*: The linux kernel configuration for  RISC-V rv64imafdc ARCH.
* *conf/evalsoc/linux_rv32imac_defconfig*: The linux kernel configuration for RISC-V rv32imac ARCH.
* *conf/evalsoc/linux_rv32imafdc_defconfig*: The linux kernel configuration for  RISC-V rv32imafdc ARCH.
* *conf/evalsoc/nuclei_rv64imac.dts*: Device tree for RISC-V rv64imac ARCH used in hardware
* *conf/evalsoc/nuclei_rv64imafdc.dts*: Device tree for RISC-V rv64imafdc ARCH used in hardware
* *conf/evalsoc/nuclei_rv32imac.dts*: Device tree for RISC-V rv32imac ARCH used in hardware
* *conf/evalsoc/nuclei_rv32imafdc.dts*: Device tree for RISC-V rv32imafdc ARCH used in hardware

> `xlspike` dts are only used internally
* *conf/evalsoc/nuclei_rv64imac_sim.dts*: Device tree for RISC-V rv64imac ARCH used in xlspike simulation
* *conf/evalsoc/nuclei_rv64imafdc_sim.dts*: Device tree for RISC-V rv64imafdc ARCH used in xlspike simulation

### Customize uboot configuration

You can customize linux kernel configuration using command `make uboot-menuconfig`, the new configuration will be saved to `conf` folder

* *conf/evalsoc/uboot_rv64imac_flash_config*: uboot configuration for RISC-V rv64imac ARCH, flash boot mode
* *conf/evalsoc/uboot_rv64imafdc_flash_config*: uboot configuration for RISC-V rv64imafdc ARCH, flash boot mode
* *conf/evalsoc/uboot_rv64imac_sd_config*: uboot configuration for RISC-V rv64imac ARCH, flash boot mode
* *conf/evalsoc/uboot_rv64imafdc_sd_config*: uboot configuration for RISC-V rv64imafdc ARCH, sd boot mode
* *conf/evalsoc/uboot_rv32imac_flash_config*: uboot configuration for RISC-V rv32imac ARCH, flash boot mode
* *conf/evalsoc/uboot_rv32imafdc_flash_config*: uboot configuration for RISC-V rv32imafdc ARCH, flash boot mode
* *conf/evalsoc/uboot_rv32imac_sd_config*: uboot configuration for RISC-V rv32imac ARCH, flash boot mode
* *conf/evalsoc/uboot_rv32imafdc_sd_config*: uboot configuration for RISC-V rv32imafdc ARCH, sd boot mode

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

> demosoc is deprecated, please take evalsoc as example.

For our current development evalsoc, we used the following resources:

* RV64IMAC or RV64IMAFDC Core, with 16 PMP entries
* DDR RAM: *0x80000000 - 0x100000000*, 2GB, DDR RAM is seperated to place opensbi, uboot, kernel, rootfs, dtb binaries.
* I/D Cache enabled
* UART @ 0x10013000
* PLIC @ 0x1C000000
* QSPI @ 0x10034000, which connect to SDCard, SDCard will be used when boot from SDCard
* QSPI @ 0x10014000, which connect to XIP SPIFlash 4M, memory mapped started at 0x20000000.

  SPIFlash is used to place freeloader, which contains opensbi, uboot, dtb, and optional kernel and rootfs
  when flash-only boot is performed. **Flash-only boot** will required at least 8M flash.

To basically port this SDK to match your target, you can make a copy of `conf/evalsoc` such as `conf/nsoc`:

* *freeloader.mk*: change the variable defined in this mk to match your design
  * **DDR_BASE**, **FLASH_BASE** and **FLASH_SIZE** are used to set DDR base address and Flash base address and size used by freeloader.
  * If you want to use SMP linux, you need to set **ENABLE_SMP** and **ENABLE_L2** to 1
  * If you only have 1 core, please make sure **ENABLE_SMP** and **ENABLE_L2** is 0
  * If you will not using amp mode, please set **AMP_START_CORE** to max hart id,
    for example, if you have four core, change it to 4.
  * **CACHE_CTRL** and **TLB_CTRL** is used to control L1/L2 cache control CSR `mcache_ctl` and TLB CTRL csr `mtlb_ctl`
  * **SPFL1DCTRL1**, **SPFL1DCTRL2** and **MERGL1DCTRL** are used to control L1 DCache Prefetch and Write Streaming or Merge Control registers `spfl1dctrl1`, `spfl1dctrl2` and `mergel1dctrl`

* *build.mk*:
  * Change **UIMAGE_AE_CMD** to match your DDR base, used by Makefile to generate rootfs for uboot.
  * If you have qemu support, you can change your qemu machine options **QEMU_MACHINE_OPTS** to match your qemu machine.
  * If you are using AMP, **CORE1_APP_BIN**, **CORE2_APP_BIN**, **CORE3_APP_BIN**, **CORE4_APP_BIN**,
    **CORE5_APP_BIN**, **CORE6_APP_BIN** and **CORE7_APP_BIN** need to be configured, CORE1-CORE7 each memory is default 4MB(configured by **AMPFW_SIZE**)
    and application base address is default offset 0x7E000000(configured by **AMPFW_START_OFFSET**) at DDR base, you can refer to https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/18 for how to use AMP demo.
    > Here each core memory is changed from 8M to 4M, due to only 32MB is reserved for amp binaries, and now we support 8 cores.
    - **CORE1_APP_BIN** start offset is **DDR_BASE** + **0x7E000000**, such as `$(confdir)/amp/c1.bin`
    - **CORE2_APP_BIN** start offset is **DDR_BASE** + **0x7E000000** + **4M**, such as `$(confdir)/amp/c2.bin`
    - **CORE3_APP_BIN** start offset is **DDR_BASE** + **0x7E000000** + **4M*2**, such as `$(confdir)/amp/c3.bin`
    - **CORE4_APP_BIN** start offset is **DDR_BASE** + **0x7E000000** + **4M*3**, such as `$(confdir)/amp/c4.bin`
    - **CORE5_APP_BIN** start offset is **DDR_BASE** + **0x7E000000** + **4M*4**, such as `$(confdir)/amp/c5.bin`
    - **CORE6_APP_BIN** start offset is **DDR_BASE** + **0x7E000000** + **4M*5**, such as `$(confdir)/amp/c6.bin`
    - **CORE7_APP_BIN** start offset is **DDR_BASE** + **0x7E000000** + **4M*6**, such as `$(confdir)/amp/c7.bin`
  * **TIMER_HZ**, **CPU_HZ**, **PERIPH_HZ** are used by `*.dts` files to generate correct timer, cpu, peripheral clock hz, if you directly
    set it in dts, not need for this variables.

* *opensbi/*: Change the opensbi support code for your soc, all the files need to be modified.

* *nuclei_rv32imac.dts*, *nuclei_rv32imafdc.dts*, *nuclei_rv64imac.dts*, *nuclei_rv64imafdc.dts* and *openocd.cfg*: Change these files to match your SoC design.
  - Select the right dts which match your cpu isa, for example, if you are using rv64imafdc, please use `nuclei_rv64imafdc.dts`
  - External interrupts connected to plic interrupt number started from 1, 0 is reserved.
    For example, in evalsoc, interrupt id of UART0 is 32, then plic interrupt number is 33,
    and if elic also present, the eclic interrupt number will be 32+19=51
  - If you want to boot linux using hvc console(console via sbi console, useful when uart driver in linux is not ready),
    you can change `bootargs` to make `console=/dev/hvc0`, then it will use sbi console to print message
  - If you UART driver in linux is ready, then you can change the console to your real uart device name.

* *uboot.cmd*: Change to match your memory map.

* *uboot_rv64imac_sd_config*, *uboot_rv64imac_flash_config*, *uboot_rv64imafdc_sd_config* and *uboot_rv64imafdc_flash_config*:
* *uboot_rv32imac_sd_config*, *uboot_rv32imac_flash_config*, *uboot_rv32imafdc_sd_config* and *uboot_rv32imafdc_flash_config*:
  change **CONFIG_SYS_TEXT_BASE** and **CONFIG_BOOTCOMMAND** to match your uboot system text address and boot command address.

* If you have a lot of changes in uboot or linux, please directly change code in it.

> In evalsoc support, spmp bypass is controlled by code in `conf/evalsoc/opensbi/platform.c` for opensbi v0.9, `conf/evalsoc/opensbi/evalsoc.c` for opensbi >= v1.2

> From commit 6507c68 on, the spmp will be bypassed(done in code as below) when tee is present(checked mcfg_info csr).
> If you have enabled TEE feature(sPMP module included), you need to configure spmp csr registers
> as this commit https://github.com/Nuclei-Software/opensbi/commit/1d28050d01b93b6afe590487324b663c65a2c429 .
> Then you will be able to boot up linux kernel, otherwise the init process will fail.

## Known issues and FAQs

> Please also track issues located in https://github.com/Nuclei-Software/nuclei-linux-sdk/issues

* Clone source code from github or gitee failed with issue `the remote end hung up unexpectedly`.

  see https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/10 for up to date answer.

  This Nuclei Linux SDK repo is a very big repo with many submodules, just simple clone is not enough, you always need to
  do submodule init and update, sometimes due to connection issue or http clone not stable issue, please switch to use ssh
  protocol used in git clone, see similar issue posted in stackoverflow, see https://stackoverflow.com/questions/6842687/the-remote-end-hung-up-unexpectedly-while-git-cloning

  Or you can try shallow submodule update:

  ~~~shell
  ## clone repo from github
  git clone https://github.com/Nuclei-Software/nuclei-linux-sdk.git
  ## if github is not working please use gitee, no longer working, deprecated now, see https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/10#issuecomment-1728920670
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

  If you want to execute using *xl_spike* without the login, you can edit the `work/$SOC/buildroot_initramfs_sysroot/etc/inittab`
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
          345   boot.scr     # boot script used by uboot, generated from ./conf/<SOC>/uboot.cmd
      3052821   uImage.lz4   # lz4 archived kernel image
      19155960  uInitrd.lz4  # lz4 archived rootfs image

      4 file(s), 0 dir(s)
     ~~~

  3. If the above steps are all correct, then you can run `boot` command to boot linux, or type commands
     located in [./conf/evalsoc/uboot.cmd](conf/evalsoc/uboot.cmd) for evalsoc.

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

  If you are familiar with the generated rootfs files located in `work/<SOC>/buildroot_initramfs_sysroot`, you can
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

  see https://github.com/Nuclei-Software/nuclei-linux-sdk/wiki/Program-freeloader


## Reference

* [Buildroot Manual](https://buildroot.org/downloads/manual/manual.html)
* [OpenSBI Manual](https://github.com/riscv/opensbi#documentation)
* [Uboot Manual](https://www.denx.de/wiki/U-Boot/Documentation)
* [Linux Manual](https://www.kernel.org/doc/html/latest/)

---

[1]: https://github.com/Nuclei-Software/nuclei-linux-sdk/actions/runs/2232759453

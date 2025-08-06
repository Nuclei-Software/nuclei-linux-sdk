# Hummingbird E603 Evaluation SoC

This guide provides instructions for building and running the **Nuclei Linux SDK**
on the [**Hummingbird E603 Evaluation SoC**](https://github.com/Nuclei-Software/e603_hbird).

## Requirements

First, clone this Nuclei Linux SDK repository and checkout to the `dev_nuclei_6.6_v3_e603` branch.

```bash
# Make sure checkout this dev_nuclei_6.6_v3_e603 branch
git clone -b dev_nuclei_6.6_v3_e603 https://github.com/Nuclei-Software/nuclei-linux-sdk
```

> [!IMPORTANT]
> Make sure to initialize and update all submodules.

```bash
# Make sure all submodule repo updated successfully
git submodule update --init --recursive
# check status of this repo to make sure it is clean and updated
git status
git submodule status
```

## How to Build

The CPU core used in the Hummingbird E603 SoC is `ux600fd`, based on the `rv64imafdc`
instruction set. The corresponding Device Tree Source (DTS) file is `nuclei_rv64imafdc.dts`.

The DTS file has been pre-configured to match the E603's hardware. You do **NOT**
need to modify it. To build the required components, simply run:

```bash
cd /path/to/nuclei-linux-sdk
make CORE=ux600fd freeloader bootimages
```

After a successful build, the generated files will be located in the `work/evalsoc/`
directory:

```bash
tree -L 1 work/evalsoc
work/evalsoc
├── boot
├── boot.zip
├── buildroot_initramfs
├── buildroot_initramfs_sysroot
├── freeloader
├── initramfs.cpio.gz
├── initramfs.cpio.gz.lz4
├── linux
├── nuclei_rv64imafdc.dtb
├── nuclei_rv64imafdc.dts.preprocessed
├── opensbi
├── README.txt
├── run.log
└── u-boot
```

- Files in `work/evalsoc/boot` are the boot materials for **SDCard boot**.
- `work/evalsoc/freeloader/freeloader.elf` is the **freeloader binary** to be loaded
onto the FPGA board.

## How to Run

### Required Hardware and Tools

- [Nuclei DDR200T Evaluation Board](https://www.nucleisys.com/developboard.php#ddr200t)
- [A Hummingbird Debugger Kit](https://www.nucleisys.com/developboard.php#debuggerkit)
- A microSD card with with sufficient capacity for boot files
- [Nuclei OpenOCD](https://doc.nucleisys.com/nuclei_tools/openocd/index.html), available
in your `PATH`
- A serial terminal tool (e.g., [minicom](https://salsa.debian.org/minicom-team/minicom),
[MobaXterm](https://mobaxterm.mobatek.net/), or similar)

### Steps to Boot Linux

1. Ensure the FPGA is properly programmed with the correct bitstream.
2. Connect the Hummingbird Debugger Kit to the board.
3. Open a UART terminal with the following settings:
    - Baud Rate: 115200
    - Data Bits: 8
    - Parity: None
    - Stop Bits: 1
    - Flow Control: None
4. Copy all files from `work/evalsoc/boot` to the microSD card.
5. Insert the microSD card into the board’s SD slot (J57, next to the TFT LCD).
6. Run `make upload_freeloader` to upload the freeloader into on-board Flash.

Once all above is done, CPU will start run, freeloader will copy opensbi
and u-boot from flash into DDR RAM, then opensbi will boot uboot, and uboot
will automatically load linux image and initramfs from SDCard and boot linux
if everything is prepared correctly.

> [!NOTE]
> Default login credentials:
> **Username**: `root`
> **Password**: `nuclei`

After booting, you’ll see the system log output in your serial terminal,
indicating that Linux is up and running.

```txt
OpenSBI v1.3
Build time: 2025-08-01 10:58:05 +0800
Build compiler: gcc version 14.2.1 20240816 (g553a166de)
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
Platform Reboot Device    : nuclei_reset
Platform Shutdown Device  : nuclei_reset
Platform Suspend Device   : ---
Platform CPPC Device      : ---
Firmware Base             : 0x80000000
Firmware Size             : 392 KB
Firmware RW Offset        : 0x40000
Firmware RW Size          : 136 KB
Firmware Heap Offset      : 0x56000
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
Domain0 Region05          : 0x0000000080000000-0x000000008003ffff M: (R,X) S/U: ()
Domain0 Region06          : 0x0000000080040000-0x000000008007ffff M: (R,W) S/U: ()
Domain0 Region07          : 0x0000000000000000-0xffffffffffffffff M: (R,W,X) S/U: (R,W,X)
Domain0 Next Address      : 0x0000000080200000
Domain0 Next Arg1         : 0x0000000088000000
Domain0 Next Mode         : S-mode
Domain0 SysReset          : yes
Domain0 SysSuspend        : yes

Boot HART ID              : 0
Boot HART Domain          : root
Boot HART Priv Version    : v1.11
Boot HART Base ISA        : rv64imafdc
Boot HART ISA Extensions  : time
Boot HART PMP Count       : 8
Boot HART PMP Granularity : 4096
Boot HART PMP Address Bits: 30
Boot HART MHPM Count      : 4
Boot HART MIDELEG         : 0x0000000000000222
Boot HART MEDELEG         : 0x000000000000b109


U-Boot 2024.01-19281-gd1308a36c5 (Aug 01 2025 - 10:58:03 +0800)

CPU:   rv64imafdc
Model: nuclei,evalsoc
DRAM:  2 GiB
Board: Initialized
Core:  25 devices, 13 uclasses, devicetree: board
MMC:   Nuclei SPI version 0xee010102
spi@10034000:mmc@0: 0
Loading Environment from nowhere... OK
In:    serial@10013000
Out:   serial@10013000
Err:   serial@10013000
Hit any key to stop autoboot:  0
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
725 bytes read in 162 ms (3.9 KiB/s)
## Executing script at 80200000
Boot images located in .
Loading kernel: ./uImage.lz4
4164221 bytes read in 17709 ms (229.5 KiB/s)
Loading ramdisk: ./uInitrd.lz4
7938099 bytes read in 33604 ms (230.5 KiB/s)
./kernel.dtb not found, ignore it
Starts booting from SD
## Booting kernel from Legacy Image at 83000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    4164157 Bytes = 4 MiB
   Load Address: 80400000
   Entry Point:  80400000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at 88300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    7938035 Bytes = 7.6 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at 88000000
   Booting using the fdt blob at 0x88000000
Working FDT set to 88000000
   Uncompressing Kernel Image
   Using Device Tree in place at 0000000088000000, end 0000000088004c97
Working FDT set to 88000000

Starting kernel ...

[    0.000000] Linux version 6.6.90+ (jdqiu@whss2.corp.nucleisys.com) (riscv64-unknown-linux-gnu-gcc (g553a166de) 14.2.1 20240816, GNU ld (GNU Binutils) 2.44) #1 SMP Fri Aug  1 10:49:24 CST 2025
[    0.000000] Machine model: nuclei,evalsoc
[    0.000000] SBI specification v1.0 detected
[    0.000000] SBI implementation ID=0x1 Version=0x10003
[    0.000000] SBI TIME extension detected
[    0.000000] SBI IPI extension detected
[    0.000000] SBI RFENCE extension detected
[    0.000000] SBI SRST extension detected
[    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
[    0.000000] printk: bootconsole [sbi0] enabled
[    0.000000] efi: UEFI not found.
[    0.000000] OF: reserved mem: 0x0000000080000000..0x000000008003ffff (256 KiB) nomap non-reusable mmode_resv0@80000000
[    0.000000] OF: reserved mem: 0x0000000080040000..0x000000008007ffff (256 KiB) nomap non-reusable mmode_resv1@80040000
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000080000000-0x00000000fdffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000080000000-0x000000008007ffff]
[    0.000000]   node   0: [mem 0x0000000080080000-0x00000000fdffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000080000000-0x00000000fdffffff]
[    0.000000] SBI HSM extension detected
[    0.000000] Falling back to deprecated "riscv,isa"
[    0.000000] riscv: base ISA extensions acdfim
[    0.000000] riscv: ELF capabilities acdfim
[    0.000000] percpu: Embedded 15 pages/cpu s24488 r8192 d28760 u61440
[    0.000000] Kernel command line: earlycon=sbi console=ttyNUC0
[    0.000000] Dentry cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] Inode-cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 509040
[    0.000000] mem auto-init: stack:all(zero), heap alloc:off, heap free:off
[    0.000000] Memory: 2007888K/2064384K available (4827K kernel code, 4729K rwdata, 2048K rodata, 2133K init, 310K bss, 56496K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=8, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=64 to nr_cpu_ids=8.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=8
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped
[    0.000000] plic: interrupt-controller@1c000000: mapped 53 interrupts with 8 handlers for 16 contexts.
[    0.000000] riscv: providing IPIs using SBI IPI extension
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000030] sched_clock: 64 bits at 33kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.011993] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.022735] pid_max: default: 32768 minimum: 301
[    0.033447] Mount-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.042572] Mountpoint-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.136260] riscv: ELF compat mode unsupported
[    0.137237] ASID allocator using 16 bits (65536 entries)
[    0.153991] rcu: Hierarchical SRCU implementation.
[    0.158660] rcu:     Max phase no-delay instances is 1000.
[    0.176910] EFI services will not be available.
[    0.211578] smp: Bringing up secondary CPUs ...
[    1.316558] CPU1: failed to come online
[    2.366516] CPU2: failed to come online
[    3.415954] CPU3: failed to come online
[    4.466003] CPU4: failed to come online
[    5.515991] CPU5: failed to come online
[    6.565704] CPU6: failed to come online
[    7.615447] CPU7: failed to come online
[    7.620635] smp: Brought up 1 node, 1 CPU
[    7.643371] devtmpfs: initialized
[    7.701385] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    7.712066] futex hash table entries: 2048 (order: 5, 131072 bytes, linear)
[    7.728759] pinctrl core: initialized pinctrl subsystem
[    7.760955] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    7.776641] DMA: preallocated 256 KiB GFP_KERNEL pool for atomic allocations
[    7.785400] DMA: preallocated 256 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
[    7.855499] cpu0: Ratio of byte access time to unaligned word access is 0.35, unaligned accesses are slow
[    7.973876] pps_core: LinuxPPS API ver. 1 registered
[    7.978729] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    7.989410] PTP clock support registered
[    8.017181] clocksource: Switched to clocksource riscv_clocksource
[    8.082122] NET: Registered PF_INET protocol family
[    8.106353] IP idents hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    8.221832] tcp_listen_portaddr_hash hash table entries: 1024 (order: 2, 16384 bytes, linear)
[    8.232513] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    8.240905] TCP established hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    8.260162] TCP bind hash table entries: 16384 (order: 7, 524288 bytes, linear)
[    8.301330] TCP: Hash tables configured (established 16384 bind 16384)
[    8.317840] UDP hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    8.327819] UDP-Lite hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    8.342407] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    8.403106] Trying to unpack rootfs image as initramfs...
[    8.411437] workingset: timestamp_bits=62 max_order=19 bucket_order=0
[   13.760803] NET: Registered PF_ALG protocol family
[   13.767272] io scheduler mq-deadline registered
[   13.771697] io scheduler kyber registered
[   13.777069] io scheduler bfq registered
[   21.492889] 10013000.serial: ttyNUC0 at MMIO 0x10013000 (irq = 12, base_baud = 3125000) is a Nuclei UART v0
[   21.503662] printk: console [ttyNUC0] enabled
[   21.503662] printk: console [ttyNUC0] enabled
[   21.512145] printk: bootconsole [sbi0] disabled
[   21.512145] printk: bootconsole [sbi0] disabled
[   22.263610] brd: module loaded
[   22.635833] loop: module loaded
[   22.653076] nuclei_spi 10014000.spi: mapped; irq=13, cs=4
[   22.745300] spi-nor spi0.0: gd25q32 (4096 Kbytes)
[   24.740417] Freeing initrd memory: 7748K
[   25.803131] ftl_cs: FTL header not found.
[   25.841888] nuclei_spi 10034000.spi: mapped; irq=14, cs=4
[   25.928192] mmc_spi spi1.0: SD/MMC host mmc0, no WP, no poweroff, cd polling
[   25.977447] NET: Registered PF_INET6 protocol family
[   26.045074] Segment Routing with IPv6
[   26.051300] In-situ OAM (IOAM) with IPv6
[   26.057708] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[   26.083770] NET: Registered PF_PACKET protocol family
[   26.358764] mmc0: host does not support reading read-only switch, assuming write-enable
[   26.367553] mmc0: new SDHC card on SPI
[   26.405395] clk: Disabling unused clocks
[   26.420562] mmcblk0: mmc0:0000 SD32G 29.7 GiB
[   26.589263] Freeing unused kernel image (initmem) memory: 2132K
[   26.595733] Run /init as init process
[   26.639678]  mmcblk0: p1
Saving 256 bits of non-creditable seed for next boot
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
eth0 device not present, will not configure it!
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory
Starting haveged: haveged: command socket is listening at fd 3
OK
Starting crond: OK

Welcome to Nuclei System Technology
nucleisys login: [   73.642608] random: crng init done

Welcome to Nuclei System Technology
nucleisys login: root
Password:
# cat /proc/cpuinfo
processor       : 0
hart            : 0
isa             : rv64imafdc_zicntr_zicsr_zifencei_zihpm
mmu             : sv39
mvendorid       : 0x2d33
marchid         : 0xe603
mimpid          : 0x20100

# uname -a
Linux nucleisys 6.6.90+ #1 SMP Fri Aug  1 10:49:24 CST 2025 riscv64 GNU/Linux
```

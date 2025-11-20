# Nuclei UX1030H Linux KVM虚拟化使用文档

本文档主要介绍在Nuclei支持H扩展的CPU IP(比如UX1030H)平台上, 怎么把linux虚拟机跑起来。

硬件：NUCLEI RISC-V Core with hypervisor extension
软件：Linux SDK + kvmtool/qemu 工具

> [!NOTE]
> - 本分支支持的是带AIA控制器的EvalSoC, 中断编号相对之前版本发生了变化，没法直接使用default nuclei qemu配置，本仓库提供的 `conf/evalsoc/evalsoc.json` 配合 Nuclei Qemu 2025.10版本即可正常使用
> - 相关的Qemu环境适配工作已经搞定，可以直接使用

## 1.编译kvmtool虚拟化应用程序

> - 本分支最新代码已经将 预编译好的 `kvmtool` + `Guest Linux Kernel 6.10` + `rootfs.img` 放在了 conf/evalsoc/kvm 目录下
> - 因此如果不想重新编译这些工具，可以直接跳过 1 + 2 步骤，也不需要手动拷贝这些工具了，这个已经做到Makefile里面
>   自动拷贝过去，只需要登录 host linux 内核以后执行 `./kvm/kvm.sh` 或者 `./kvm/qemu.sh` 即可体验, 执行log参见 d554b5406e

kvmtool 是一个轻量级的工具，用于在 Linux 上托管 KVM 客户机，它是一个纯虚拟化工具，仅支持运行相同架构的客户机。
*如果使用``dev_nuclei_6.12_v3_hypervisor_aia``分支跑虚拟化，可以使用linux sdk自带的qemu工具，此步骤可跳过。*

1）编译dtc，安装libfdt库到toolchain lib

```shell
git clone git://git.kernel.org/pub/scm/utils/dtc/dtc.git
cd dtc
export ARCH=riscv
export CROSS_COMPILE=riscv64-unknown-linux-gnu-
export CC="${CROSS_COMPILE}gcc -mabi=lp64d -march=rv64gc" # riscv toolchain should be configured with --enable-multilib to support the most common -march/-mabi options if you build it from source code
export SYSROOT=$($CC -print-sysroot)
make libfdt  -j4
make NO_PYTHON=1 NO_YAML=1 DESTDIR=$SYSROOT PREFIX=/usr LIBDIR=/usr/lib64/lp64d install-lib install-includes
cd ..
```
**CROSS_COMPILE 可根据实际情况设置。**

2）编译kvmtool

```shell
git clone https://git.kernel.org/pub/scm/linux/kernel/git/will/kvmtool.git
export RISCV_XLEN=64
export ARCH=riscv
export CROSS_COMPILE=riscv64-unknown-linux-gnu-
cd kvmtool
make lkvm-static  -j4
${CROSS_COMPILE}strip lkvm-static
cd ..
```
编译生成的目标文件kvmtool/lkvm-static，后续放在host linux sdk rootfs中。

## 2.编译guest linux 内核

此处以linux v6.6内核为例，其他版本内核也可参考编译

```shell
# You can clone it from github or directly copy <linux-sdk>/linux folder to a new folder such as linux_virt
# linux sdk can be clone using steps described in 3
# and cd to linux_virt
git clone https://github.com/Nuclei-Software/linux.git -b dev_nuclei_6.6.y
cd linux
make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- defconfig
make ARCH=riscv CROSS_COMPILE=riscv64-unknown-linux-gnu- -j4
```
编译生成的目标文件linux/arch/riscv/boot/Image，后续放在host linux sdk rootfs中。

*注意*：这里使用的是linux 自带的defconfig配置

## 3.编译运行host linux sdk

获取Nuclei linux SDK 源码, 切换到hypervisor 分支，目前hypervisor分支有两个：一个是支持PLIC中断控制器的虚拟化分支：``dev_nuclei_6.6_v3_hypervisor``，另外一个是支持AIA中断控制器的虚拟化分支：``dev_nuclei_6.12_v3_hypervisor_aia``，下面以``dev_nuclei_6.6_v3_hypervisor``分支为例说明：

```shell
# 参考 https://github.com/Nuclei-Software/nuclei-linux-sdk/issues/10 来clone代码，注意切分支
git clone -b dev_nuclei_6.6_v3_hypervisor https://github.com/Nuclei-Software/nuclei-linux-sdk
cd nuclei-linux-sdk
git submodule init
git submodule update --depth 1
# TODO: 如果你确认你的evalsoc支持XEC网络，请使能 nuclei_rv64imafdc.dts -> xec0 -> status: disabled -> okay
# 如果你需要网络相关的特性，这个XEC是务必带上的，请使用支持XEC的evalsoc的bitstream来进行测试
make SOC=evalsoc CORE=ux900fd freeloader -j4
make SOC=evalsoc CORE=ux900fd bootimages -j4
cd ..
```

> [!CAUTION]
> **注意**：在linux上使用aia中断控制器时，dts中cpu节点个数要按照实际情况来写，不支持自动探测不存在的core，因为ipi通过msi中断来实现，imsic在core内部，core不存在时，imsic对应的地址我们硬件没有实现，所以软件dts 配置的cpu core数目要小于等于硬件cpu core数目。

将前面编译的``lkvm-static``，guest linux内核``Image`` 拷贝到rootfs中，重新编译rootfs。

*注意：如果使用``dev_nuclei_6.12_v3_hypervisor_aia``分支，则可以使用linux sdk中编译的qemu工具来跑虚拟化，不需要使用lkvm-static*

```shell
# 如果是使用我们仓库里面预编译好的kvm tool和guest linux kernel，下面的命令不需要运行
cp kvmtool/lkvm-static nuclei-linux-sdk/work/evalsoc/buildroot_initramfs_sysroot/usr/bin/
cp linux/arch/riscv/boot/Image nuclei-linux-sdk/work/evalsoc/buildroot_initramfs_sysroot/usr/bin/
cd nuclei-linux-sdk
rm work/evalsoc/initramfs.cpio.gz* -rf
make SOC=evalsoc CORE=ux900fd bootimages -j4
```

将freeloader烧录到FPGA norflash上，boot images 存放到SD卡上，复位FPGA运行linux sdk。
关于编译烧录运行linux sdk，请参考Nuclei Linux sdk doc.

## 4.kvmtool启动guest linux

```
#linux host sdk启动过程省略
....
Saving 256 bits of non-creditable seed for next boot
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
eth0 device not present, will not configure it!
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory

Welcome to Nuclei System Technology
nucleisys login: root
Password:
# cd /usr/bin/
//启动虚拟机内核Image 运行
# lkvm-static run -m 1024 -c1 -k Image
```

lkvm-static 各参数的含义可以用-h查看。

Nuclei host linux sdk 支持ssh登录，所以可以通过ssh客户端登录host linux，然后在ssh 客户端上运行lkvm-static 创建新的虚拟机。
在Nuclei FPGA平台上可以创建多个虚拟机同时运行。

## 5.qemu启动guest linux

```
#linux host sdk启动过程省略
....
Saving 256 bits of non-creditable seed for next boot
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
eth0 device not present, will not configure it!
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory

Welcome to Nuclei System Technology
nucleisys login: root
Password:
/* 此处挂载sd卡到/mnt目录，如果linux host rootfs放在flash上，则可以自行将guest linux和guest rootfs放在host rootfs中 */
# mount /dev/mmcblk0p1 /mnt/
# qemu-system-riscv64 -M virt,aia=aplic-imsic --enable-kvm -m 1.5G -smp 4 -nographic -kernel /mnt/Image_6.10 -initrd /mnt/rootfs.img -virtfs local,path=/mnt/,mount_tag=myshare_tag,security_model=none

```

Nuclei host linux sdk 支持ssh登录，所以可以通过ssh客户端登录host linux，然后在ssh 客户端上运行qemu创建新的虚拟机。在Nuclei FPGA平台上可以创建多个虚拟机同时运行。


## 6.host linux 共享文件给guest linux 虚拟机

Nuclei host linux 内核支持9P文件系统，通过9P文件系统可以将host linux rootfs 目录共享给guest linux虚拟机使用。

下面是配置命令

1.host 端配置`/tmp/myshared/` 共享目录

- lkvm 工具共享命令：

host 共享`/tmp/myshared` 给guest

```shell
mkdir -p /tmp/myshared/
mount /dev/mmcblk0p1 /tmp/myshared/
lkvm-static run --9p /tmp/myshared,myshare_tag -m 1536 -c1 -k Image
```

- qemu 工具共享命令：

host 共享`/mnt` 给guest

```shell
qemu-system-riscv64 -M virt,aia=aplic-imsic --enable-kvm -m 1.5G -smp 4 -nographic -kernel /mnt/Image_6.10 -initrd /mnt/rootfs.img -virtfs local,path=/mnt/,mount_tag=myshare_tag,security_model=none
```


2.guest 端挂载host共享目录到本地目录/fromhost

guest挂载共享目录方式相同。

```shell
mkdir -p /fromhost
mount -t 9p -o trans=virtio myshare_tag /fromhost
```

guest 可以从`/fromhost` 目录访问host共享目录内容

## 7.host linux与guest linux启动打印

- lkvm工具启动guest linux的打印

```
OpenSBI v1.3
Build time: 2025-07-11 23:38:17 +0800
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
Firmware Heap Size        : 48 KB (total), 3 KB (reserved), 9 KB (used), 35 KB (                               free)
Firmware Scratch Size     : 4096 B (total), 760 B (used), 3336 B (free)
Runtime SBI Version       : 1.0

Domain0 Name              : root
Domain0 Boot HART         : 0
Domain0 HARTs             : 0*,1*,2*,3*,4*,5*,6*,7*
Domain0 Region00          : 0x0000000018031000-0x0000000018031fff M: (I,R,W) S/U                               : ()
Domain0 Region01          : 0x000000001803c000-0x000000001803cfff M: (I,R,W) S/U                               : ()
Domain0 Region02          : 0x0000000018032000-0x0000000018033fff M: (I,R,W) S/U                               : ()
Domain0 Region03          : 0x0000000018034000-0x0000000018037fff M: (I,R,W) S/U                               : ()
Domain0 Region04          : 0x0000000018038000-0x000000001803bfff M: (I,R,W) S/U                               : ()
Domain0 Region05          : 0x0000000080000000-0x000000008003ffff M: (R,X) S/U:                                ()
Domain0 Region06          : 0x0000000080040000-0x000000008007ffff M: (R,W) S/U:                                ()
Domain0 Region07          : 0x0000000000000000-0xffffffffffffffff M: (R,W,X) S/U                               : (R,W,X)
Domain0 Next Address      : 0x0000000080200000
Domain0 Next Arg1         : 0x0000000088000000
Domain0 Next Mode         : S-mode
Domain0 SysReset          : yes
Domain0 SysSuspend        : yes

Boot HART ID              : 0
Boot HART Domain          : root
Boot HART Priv Version    : v1.12
Boot HART Base ISA        : rv64imafdcbvhk
Boot HART ISA Extensions  : sscofpmf,time,smaia,smstateen,sstc
Boot HART PMP Count       : 16
Boot HART PMP Granularity : 4096
Boot HART PMP Address Bits: 33
Boot HART MHPM Count      : 4
Boot HART MIDELEG         : 0x0000000000003666
Boot HART MEDELEG         : 0x0000000000f0b509


U-Boot 2024.01-gd1308a36c57 (Jul 11 2025 - 23:38:09 +0800)

CPU:   rv64imafdcvh_zicbom_svpbmt_sstc
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
=>
=>
=>
=> setenv bootloc 6.6_rv64_hypervisor
=> boot
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
725 bytes read in 264 ms (2 KiB/s)
## Executing script at 80200000
Boot images located in 6.6_rv64_hypervisor
Loading kernel: 6.6_rv64_hypervisor/uImage.lz4
4289272 bytes read in 16622 ms (252 KiB/s)
Loading ramdisk: 6.6_rv64_hypervisor/uInitrd.lz4
23511722 bytes read in 88737 ms (257.8 KiB/s)
6.6_rv64_hypervisor/kernel.dtb not found, ignore it
Starts booting from SD
## Booting kernel from Legacy Image at 83000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    4289208 Bytes = 4.1 MiB
   Load Address: 80400000
   Entry Point:  80400000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at 88300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    23511658 Bytes = 22.4 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at 88000000
   Booting using the fdt blob at 0x88000000
Working FDT set to 88000000
   Uncompressing Kernel Image
   Using Device Tree in place at 0000000088000000, end 0000000088004d4f
Working FDT set to 88000000

Starting kernel ...

[    0.000000] Linux version 6.6.90+ (guibing@whml1.corp.nucleisys.com) (riscv64-unknown-linux-gnu-gcc (g553a166de) 14.2.1 20240816, GNU ld (GNU Binutils) 2.44) #1 SMP Fri Jul 11 23:38:54 CST 2025
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
[    0.000000] riscv: base ISA extensions acdfhimv
[    0.000000] riscv: ELF capabilities acdfimv
[    0.000000] percpu: Embedded 16 pages/cpu s25512 r8192 d31832 u65536
[    0.000000] Kernel command line: earlycon=sbi console=ttyNUC0
[    0.000000] Dentry cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] Inode-cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 509040
[    0.000000] mem auto-init: stack:all(zero), heap alloc:off, heap free:off
[    0.000000] Memory: 1992640K/2064384K available (4981K kernel code, 4734K rwdata, 2048K rodata, 2134K init, 310K bss, 71744K reserved, 0K cma-reserved)
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
[    0.000000] sched_clock: 64 bits at 33kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.008392] riscv-timer: Timer interrupt in S-mode is available via sstc extension
[    0.017425] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.027160] pid_max: default: 32768 minimum: 301
[    0.033233] Mount-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.040344] Mountpoint-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.067687] riscv: ELF compat mode unsupported
[    0.067901] ASID allocator using 16 bits (65536 entries)
[    0.078674] rcu: Hierarchical SRCU implementation.
[    0.083038] rcu:     Max phase no-delay instances is 1000.
[    0.090759] EFI services will not be available.
[    0.100585] smp: Bringing up secondary CPUs ...
[    1.146270] CPU1: failed to come online
[    2.187225] CPU2: failed to come online
[    3.228332] CPU3: failed to come online
[    4.269470] CPU4: failed to come online
[    5.310577] CPU5: failed to come online
[    6.351684] CPU6: failed to come online
[    7.392791] CPU7: failed to come online
[    7.396453] smp: Brought up 1 node, 1 CPU
[    7.406219] devtmpfs: initialized
[    7.433654] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    7.443145] futex hash table entries: 2048 (order: 5, 131072 bytes, linear)
[    7.451934] pinctrl core: initialized pinctrl subsystem
[    7.465332] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    7.476257] DMA: preallocated 256 KiB GFP_KERNEL pool for atomic allocations
[    7.484527] DMA: preallocated 256 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
[    7.553192] cpu0: Ratio of byte access time to unaligned word access is 0.10, unaligned accesses are slow
[    7.603393] pps_core: LinuxPPS API ver. 1 registered
[    7.607818] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    7.617279] PTP clock support registered
[    7.629699] clocksource: Switched to clocksource riscv_clocksource
[    7.652343] NET: Registered PF_INET protocol family
[    7.659271] IP idents hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    7.701232] tcp_listen_portaddr_hash hash table entries: 1024 (order: 2, 16384 bytes, linear)
[    7.709777] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    7.717102] TCP established hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    7.727630] TCP bind hash table entries: 16384 (order: 7, 524288 bytes, linear)
[    7.742523] TCP: Hash tables configured (established 16384 bind 16384)
[    7.749908] UDP hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    7.756866] UDP-Lite hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    7.765808] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    7.771728] kvm [1]: hypervisor extension available
[    7.776031] kvm [1]: using Sv48x4 G-stage page table format
[    7.781768] kvm [1]: VMID 14 bits available
[    7.793212] Trying to unpack rootfs image as initramfs...
[    9.029113] workingset: timestamp_bits=62 max_order=19 bucket_order=0
[    9.040618] 9p: Installing v9fs 9p2000 file system support
[    9.841094] NET: Registered PF_ALG protocol family
[    9.845733] io scheduler mq-deadline registered
[    9.850067] io scheduler kyber registered
[    9.854187] io scheduler bfq registered
[   14.446319] 10013000.serial: ttyNUC0 at MMIO 0x10013000 (irq = 12, base_baud = 3125000) is a Nuclei UART v0
[   14.456085] printk: console [ttyNUC0] enabled
[   14.456085] printk: console [ttyNUC0] enabled
[   14.464385] printk: bootconsole [sbi0] disabled
[   14.464385] printk: bootconsole [sbi0] disabled
[   15.914916] brd: module loaded
[   15.989990] loop: module loaded
[   15.997436] nuclei_spi 10014000.spi: mapped; irq=13, cs=4
[   16.071624] spi-nor spi0.0: w25q128 (16384 Kbytes)
[   18.483032] Freeing initrd memory: 22956K
[   18.791717] ftl_cs: FTL header not found.
[   18.808013] nuclei_spi 10034000.spi: mapped; irq=14, cs=4
[   18.967651] nuclei-xec 10002000.xec eth0: using RGMII interface
[   18.975280] Generic PHY 10002000.xec-ffffffff:00: attached PHY driver (mii_bus:phy_addr=10002000.xec-ffffffff:00, irq=POLL)
[   18.985961] nuclei-xec 10002000.xec eth0: XEC mac at 0x10002000 irq 15
[   19.040039] mmc_spi spi1.0: SD/MMC host mmc0, no WP, no poweroff, cd polling
[   19.053619] NET: Registered PF_INET6 protocol family
[   19.073547] Segment Routing with IPv6
[   19.077148] In-situ OAM (IOAM) with IPv6
[   19.081542] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[   19.093963] NET: Registered PF_PACKET protocol family
[   19.101989] 9pnet: Installing 9P2000 support
[   19.202758] clk: Disabling unused clocks
[   19.224456] Freeing unused kernel image (initmem) memory: 2132K
[   19.230194] Run /init as init process
[   19.344116] mmc0: host does not support reading read-only switch, assuming write-enable
[   19.351898] mmc0: new SDXC card on SPI
[   19.384155] mmcblk0: mmc0:0000 SN64G 59.5 GiB
[   19.440338]  mmcblk0: p1
Saving 256 bits of non-creditable seed for next boot
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Configure eth0 autoneg off speed 100 duplex full!
udhcpc: started, v1.36.1
Starting mdev... OK
udhcpc: broadcasting discover
udhcpc: broadcasting discover
udhcpc: broadcasting select for 192.168.40.149, server 192.168.40.1
udhcpc: lease of 192.168.40.149 obtained from 192.168.40.1, lease time 7200
deleting routers
adding dns 192.168.55.101
adding dns 192.168.55.102
adding dns 192.168.55.105
modprobe: can't change directory to '/lib/modules': No such file or directory
Starting haveged: haveged: command socket is listening at fd 3
OK
Starting crond: OK
[   33.726501] random: crng init done
ssh-keygen: generating new host keys: RSA ECDSA ED25519
Starting sshd: OK

Welcome to Nuclei System Technology
nucleisys login: root
Password:
# uname -a
Linux nucleisys 6.6.90+ #1 SMP Fri Jul 11 23:38:54 CST 2025 riscv64 GNU/Linux
# cat /proc/cpuinfo
processor       : 0
hart            : 0
isa             : rv64imafdcvh_zicbom_zicntr_zicsr_zifencei_zihpm_sstc_svpbmt
mmu             : sv48
mvendorid       : 0x536
marchid         : 0x1000
mimpid          : 0x10300

# cd /usr/bin/
#
#
#
# mkdir -p /tmp/myshared/
# mount /dev/mmcblk0p1 /tmp/myshared/
[ 1075.290435] FAT-fs (mmcblk0p1): Volume was not properly unmounted. Some data may be corrupt. Please run fsck.
# pwd
/usr/bin
# lkvm-static run --9p /tmp/myshared,myshare_tag -m 1536 -c1 -k Image
  Info: # lkvm run -k Image -m 1536 -c 1 --name guest-153
  Warning: KVM_SET_ONE_REG failed (sbi_ext 9)
[    0.000000] Linux version 6.6.90-ged547e1b4c49 (guibing@whml1.corp.nucleisys.com) (riscv64-unknown-linux-gnu-gcc (g553a166de) 14.2.1 20240816, GNU ld (GNU Binutils) 2.44) #2 SMP Thu Jul  3 16:31:00 CST 2025
[    0.000000] Machine model: linux,dummy-virt
[    0.000000] SBI specification v1.0 detected
[    0.000000] SBI implementation ID=0x3 Version=0x6065a
[    0.000000] SBI TIME extension detected
[    0.000000] SBI IPI extension detected
[    0.000000] SBI RFENCE extension detected
[    0.000000] SBI SRST extension detected
[    0.000000] efi: UEFI not found.
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000080000000-0x00000000dfffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000080000000-0x00000000dfffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000080000000-0x00000000dfffffff]
[    0.000000] SBI HSM extension detected
[    0.000000] Falling back to deprecated "riscv,isa"
[    0.000000] riscv: base ISA extensions acdfimv
[    0.000000] riscv: ELF capabilities acdfimv
[    0.000000] percpu: Embedded 19 pages/cpu s39352 r8192 d30280 u77824
[    0.000000] Kernel command line:  console=ttyS0 rw rootflags=trans=virtio,version=9p2000.L,cache=loose rootfstype=9p init=/virt/init  ip=dhcp
[    0.000000] Dentry cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] Inode-cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 387072
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Virtual kernel memory layout:
[    0.000000]       fixmap : 0xffff8d7ffea00000 - 0xffff8d7fff000000   (6144 kB)
[    0.000000]       pci io : 0xffff8d7fff000000 - 0xffff8d8000000000   (  16 MB)
[    0.000000]      vmemmap : 0xffff8d8000000000 - 0xffff8f8000000000   (2048 GB)
[    0.000000]      vmalloc : 0xffff8f8000000000 - 0xffffaf8000000000   (  32 TB)
[    0.000000]      modules : 0xffffffff0157b000 - 0xffffffff80000000   (2026 MB)
[    0.000000]       lowmem : 0xffffaf8000000000 - 0xffffaf8060000000   (1536 MB)
[    0.000000]       kernel : 0xffffffff80000000 - 0xffffffffffffffff   (2047 MB)
[    0.000000] Memory: 1506124K/1572864K available (9172K kernel code, 4976K rwdata, 4096K rodata, 2198K init, 482K bss, 66740K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=64 to nr_cpu_ids=1.
[    0.000000] rcu:     RCU debug extended QS entry/exit.
[    0.000000]  Tracing variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 25 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=1
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped
[    0.000000] plic: interrupt-controller@08000000: mapped 1023 interrupts with 1 handlers for 2 contexts.
[    0.000000] riscv: providing IPIs using SBI IPI extension
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000030] sched_clock: 64 bits at 33kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.000640] riscv-timer: Timer interrupt in S-mode is available via sstc extension
[    0.010070] Console: colour dummy device 80x25
[    0.013580] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=131)
[    0.014068] pid_max: default: 32768 minimum: 301
[    0.021392] LSM: initializing lsm=capability,integrity
[    0.030090] Mount-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.032135] Mountpoint-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.161560] RCU Tasks Trace: Setting shift to 0 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=1.
[    0.165954] riscv: ELF compat mode unsupported
[    0.168243] ASID allocator using 16 bits (65536 entries)
[    0.175842] rcu: Hierarchical SRCU implementation.
[    0.176025] rcu:     Max phase no-delay instances is 1000.
[    0.190490] EFI services will not be available.
[    0.198852] smp: Bringing up secondary CPUs ...
[    0.200439] smp: Brought up 1 node, 1 CPU
[    0.240753] devtmpfs: initialized
[    0.330108] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645041785100000 ns
[    0.330688] futex hash table entries: 256 (order: 2, 16384 bytes, linear)
[    0.339965] pinctrl core: initialized pinctrl subsystem
[    0.416015] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.456542] DMA: preallocated 256 KiB GFP_KERNEL pool for atomic allocations
[    0.470672] DMA: preallocated 256 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
[    0.473266] audit: initializing netlink subsys (disabled)
[    0.509216] thermal_sys: Registered thermal governor 'step_wise'
[    0.511596] audit: type=2000 audit(0.436:1): state=initialized audit_enabled=0 res=1
[    0.513427] cpuidle: using governor menu
[    0.550811] cpu0: Ratio of byte access time to unaligned word access is 0.10, unaligned accesses are slow
[    0.700469] HugeTLB: registered 2.00 MiB page size, pre-allocated 0 pages
[    0.700866] HugeTLB: 28 KiB vmemmap can be freed for a 2.00 MiB page
[    0.727874] ACPI: Interpreter disabled.
[    0.733947] iommu: Default domain type: Translated
[    0.734130] iommu: DMA domain TLB invalidation policy: strict mode
[    0.769104] SCSI subsystem initialized
[    0.793121] usbcore: registered new interface driver usbfs
[    0.795898] usbcore: registered new interface driver hub
[    0.798339] usbcore: registered new device driver usb
[    0.868438] vgaarb: loaded
[    0.878967] clocksource: Switched to clocksource riscv_clocksource
[    0.908935] pnp: PnP ACPI: disabled
[    1.373260] NET: Registered PF_INET protocol family
[    1.396789] IP idents hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    1.472351] tcp_listen_portaddr_hash hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    1.479553] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    1.480072] TCP established hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    1.490020] TCP bind hash table entries: 16384 (order: 8, 1048576 bytes, linear)
[    1.696350] TCP: Hash tables configured (established 16384 bind 16384)
[    1.705993] UDP hash table entries: 1024 (order: 4, 98304 bytes, linear)
[    1.722045] UDP-Lite hash table entries: 1024 (order: 4, 98304 bytes, linear)
[    1.747619] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    1.782989] RPC: Registered named UNIX socket transport module.
[    1.783233] RPC: Registered udp transport module.
[    1.783447] RPC: Registered tcp transport module.
[    1.783630] RPC: Registered tcp-with-tls transport module.
[    1.783813] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    1.784271] PCI: CLS 0 bytes, default 64
[    1.837463] workingset: timestamp_bits=46 max_order=19 bucket_order=0
[    1.875732] NFS: Registering the id_resolver key type
[    1.879333] Key type id_resolver registered
[    1.879638] Key type id_legacy registered
[    1.881866] nfs4filelayout_init: NFSv4 File Layout Driver Registering...
[    1.882720] nfs4flexfilelayout_init: NFSv4 Flexfile Layout Driver Registering...
[    1.892425] 9p: Installing v9fs 9p2000 file system support
[    1.907287] NET: Registered PF_ALG protocol family
[    1.909912] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 246)
[    1.911315] io scheduler mq-deadline registered
[    1.911651] io scheduler kyber registered
[    1.912445] io scheduler bfq registered
[    1.950134] pci-host-generic 30000000.pci: host bridge /smb/pci ranges:
[    1.954254] pci-host-generic 30000000.pci:       IO 0x0000000000..0x000000ffff -> 0x0000000000
[    1.956298] pci-host-generic 30000000.pci:      MEM 0x0040000000..0x007fffffff -> 0x0040000000
[    1.960937] pci-host-generic 30000000.pci: ECAM at [mem 0x30000000-0x3fffffff] for [bus 00-01]
[    1.969696] pci-host-generic 30000000.pci: PCI host bridge to bus 0000:00
[    1.969970] pci_bus 0000:00: root bus resource [bus 00-01]
[    1.971099] pci_bus 0000:00: root bus resource [io  0x0000-0xffff]
[    1.971343] pci_bus 0000:00: root bus resource [mem 0x40000000-0x7fffffff]
[    1.975708] pci 0000:00:00.0: [1af4:1049] type 00 class 0xff0000
[    1.979858] pci 0000:00:00.0: reg 0x10: [io  0x6200-0x62ff]
[    1.981628] pci 0000:00:00.0: reg 0x14: [mem 0x40000000-0x400000ff]
[    1.983215] pci 0000:00:00.0: reg 0x18: [mem 0x40000400-0x400007ff]
[    2.009521] pci 0000:00:01.0: [1af4:1049] type 00 class 0xff0000
[    2.011993] pci 0000:00:01.0: reg 0x10: [io  0x6300-0x63ff]
[    2.013183] pci 0000:00:01.0: reg 0x14: [mem 0x40000800-0x400008ff]
[    2.014739] pci 0000:00:01.0: reg 0x18: [mem 0x40000c00-0x40000fff]
[    2.038574] pci 0000:00:02.0: [1af4:1049] type 00 class 0xff0000
[    2.040710] pci 0000:00:02.0: reg 0x10: [io  0x6400-0x64ff]
[    2.041900] pci 0000:00:02.0: reg 0x14: [mem 0x40001000-0x400010ff]
[    2.043395] pci 0000:00:02.0: reg 0x18: [mem 0x40001400-0x400017ff]
[    2.067382] pci 0000:00:03.0: [1af4:1041] type 00 class 0x020000
[    2.069335] pci 0000:00:03.0: reg 0x10: [io  0x6500-0x65ff]
[    2.071044] pci 0000:00:03.0: reg 0x14: [mem 0x40001800-0x400018ff]
[    2.072235] pci 0000:00:03.0: reg 0x18: [mem 0x40001c00-0x40001fff]
[    2.109344] pci 0000:00:00.0: BAR 2: assigned [mem 0x40000000-0x400003ff]
[    2.110168] pci 0000:00:01.0: BAR 2: assigned [mem 0x40000400-0x400007ff]
[    2.111511] pci 0000:00:02.0: BAR 2: assigned [mem 0x40000800-0x40000bff]
[    2.112213] pci 0000:00:03.0: BAR 2: assigned [mem 0x40000c00-0x40000fff]
[    2.112854] pci 0000:00:00.0: BAR 0: assigned [io  0x0100-0x01ff]
[    2.113525] pci 0000:00:00.0: BAR 1: assigned [mem 0x40001000-0x400010ff]
[    2.114166] pci 0000:00:01.0: BAR 0: assigned [io  0x0200-0x02ff]
[    2.115142] pci 0000:00:01.0: BAR 1: assigned [mem 0x40001100-0x400011ff]
[    2.115783] pci 0000:00:02.0: BAR 0: assigned [io  0x0300-0x03ff]
[    2.116424] pci 0000:00:02.0: BAR 1: assigned [mem 0x40001200-0x400012ff]
[    2.117034] pci 0000:00:03.0: BAR 0: assigned [io  0x0400-0x04ff]
[    2.118133] pci 0000:00:03.0: BAR 1: assigned [mem 0x40001300-0x400013ff]
[    5.076843] Serial: 8250/16550 driver, 4 ports, IRQ sharing disabled
[    5.223388] printk: console [ttyS0] disabled
[    5.243286] 10000000.U6_16550A: ttyS0 at MMIO 0x10000000 (irq = 16, base_baud = 115200) is a 16550A
[    5.245666] printk: console [ttyS0] enabled
[    9.212738] 10001000.U6_16550A: ttyS1 at MMIO 0x10001000 (irq = 17, base_baud = 115200) is a 16550A
[    9.319061] 10002000.U6_16550A: ttyS2 at MMIO 0x10002000 (irq = 18, base_baud = 115200) is a 16550A
[    9.429199] 10003000.U6_16550A: ttyS3 at MMIO 0x10003000 (irq = 19, base_baud = 115200) is a 16550A
[    9.482299] SuperH (H)SCI(F) driver initialized
[    9.883636] loop: module loaded
[   10.111389] e1000e: Intel(R) PRO/1000 Network Driver
[   10.132965] e1000e: Copyright(c) 1999 - 2015 Intel Corporation.
[   10.205230] usbcore: registered new interface driver uas
[   10.231414] usbcore: registered new interface driver usb-storage
[   10.265838] mousedev: PS/2 mouse device common for all mice
[   10.333374] sdhci: Secure Digital Host Controller Interface driver
[   10.359436] sdhci: Copyright(c) Pierre Ossman
[   10.384033] sdhci-pltfm: SDHCI platform and OF driver helper
[   10.423797] usbcore: registered new interface driver usbhid
[   10.447326] usbhid: USB HID core driver
[   10.491790] NET: Registered PF_INET6 protocol family
[   10.588592] Segment Routing with IPv6
[   10.607360] In-situ OAM (IOAM) with IPv6
[   10.631988] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[   10.697265] NET: Registered PF_PACKET protocol family
[   10.725006] 9pnet: Installing 9P2000 support
[   10.785156] Key type dns_resolver registered
[   12.289672] debug_vm_pgtable: [debug_vm_pgtable         ]: Validating architecture page table helpers
[   12.445709] Sending DHCP requests ., OK
[   12.479003] IP-Config: Got DHCP answer from 192.168.33.1, my address is 192.168.33.15
[   12.511474] IP-Config: Complete:
[   12.525299]      device=eth0, hwaddr=02:15:15:15:15:15, ipaddr=192.168.33.15, mask=255.255.255.0, gw=192.168.33.1
[   12.568145]      host=192.168.33.15, domain=, nis-domain=(none)
[   12.592651]      bootserver=192.168.33.1, rootserver=0.0.0.0, rootpath=
[   12.592834]      nameserver0=192.168.55.101
[   12.643676] clk: Disabling unused clocks
[   12.688781] 9pnet_virtio: no channels available for device
[   12.738861] VFS: Mounted root (9p filesystem) on device 0:18.
[   12.769805] devtmpfs: mounted
[   12.900146] Freeing unused kernel image (initmem) memory: 2196K
[   12.922637] Run /virt/init as init process
Mounting...
sh-5.2# uname -a
Linux 192.168.33.15 6.6.90-ged547e1b4c49 #2 SMP Thu Jul  3 16:31:00 CST 2025 riscv64 GNU/Linux
sh-5.2# cat /proc/cpuinfo
processor       : 0
hart            : 0
isa             : rv64imafdcv_zicbom_zicntr_zicsr_zifencei_zihpm_sstc_svpbmt
mmu             : sv48
mvendorid       : 0x536
marchid         : 0x1000
mimpid          : 0x10300

sh-5.2# mkdir -p /fromhost
sh-5.2# mount -t 9p -o trans=virtio myshare_tag /fromhost
sh-5.2# cd /fromhost/
sh-5.2# ls /fromhost/6.6_rv64_hypervisor
bak          boot.scr     uImage.lz4   uInitrd.lz4
sh-5.2# ping www.baidu.com
PING www.baidu.com (183.2.172.177): 56 data bytes
64 bytes from 183.2.172.177: seq=0 ttl=64 time=34.637 ms
64 bytes from 183.2.172.177: seq=1 ttl=64 time=4.852 ms
64 bytes from 183.2.172.177: seq=2 ttl=64 time=5.402 ms
64 bytes from 183.2.172.177: seq=3 ttl=64 time=4.638 ms
^C
--- www.baidu.com ping statistics ---
4 packets transmitted, 4 packets received, 0% packet loss
round-trip min/avg/max = 4.638/12.382/34.637 ms
sh-5.2#

```

- qemu工具启动guest的打印

```
OpenSBI v1.3
Build time: 2025-11-14 14:57:11 +0800
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
Platform HART Count       : 1
Platform IPI Device       : aia-imsic
Platform Timer Device     : aclint-mtimer @ 32768Hz
Platform Console Device   : nuclei_uart
Platform HSM Device       : ---
Platform PMU Device       : ---
Platform Reboot Device    : nuclei_reset
Platform Shutdown Device  : nuclei_reset
Platform Suspend Device   : ---
Platform CPPC Device      : ---
Firmware Base             : 0x80000000
Firmware Size             : 322 KB
Firmware RW Offset        : 0x40000
Firmware RW Size          : 66 KB
Firmware Heap Offset      : 0x48000
Firmware Heap Size        : 34 KB (total), 2 KB (reserved), 10 KB (used), 22 KB  (free)
Firmware Scratch Size     : 4096 B (total), 752 B (used), 3344 B (free)
Runtime SBI Version       : 1.0

Domain0 Name              : root
Domain0 Boot HART         : 0
Domain0 HARTs             : 0*
Domain0 Region00          : 0x0000000018031000-0x0000000018031fff M: (I,R,W) S/U                                                                             : ()
Domain0 Region01          : 0x000000001803c000-0x000000001803cfff M: (I,R,W) S/U                                                                             : ()
Domain0 Region02          : 0x0000000018032000-0x0000000018033fff M: (I,R,W) S/U                                                                             : ()
Domain0 Region03          : 0x0000000010040000-0x0000000010043fff M: (I,R,W) S/U                                                                             : ()
Domain0 Region04          : 0x0000000018034000-0x0000000018037fff M: (I,R,W) S/U                                                                             : ()
Domain0 Region05          : 0x0000000018038000-0x000000001803bfff M: (I,R,W) S/U                                                                             : ()
Domain0 Region06          : 0x000000004f000000-0x000000004f007fff M: (I,R,W) S/U                                                                             : ()
Domain0 Region07          : 0x0000000080040000-0x000000008005ffff M: (R,W) S/U:                                                                              ()
Domain0 Region08          : 0x0000000080000000-0x000000008003ffff M: (R,X) S/U:                                                                              ()
Domain0 Region09          : 0x0000000000000000-0xffffffffffffffff M: (R,W,X) S/U                                                                             : (R,W,X)
Domain0 Next Address      : 0x0000000080200000
Domain0 Next Arg1         : 0x0000000088000000
Domain0 Next Mode         : S-mode
Domain0 SysReset          : yes
Domain0 SysSuspend        : yes

Boot HART ID              : 0
Boot HART Domain          : root
Boot HART Priv Version    : v1.12
Boot HART Base ISA        : rv64imafdcbvh
Boot HART ISA Extensions  : sscofpmf,time,smaia,smstateen,sstc
Boot HART PMP Count       : 16
Boot HART PMP Granularity : 4096
Boot HART PMP Address Bits: 33
Boot HART MHPM Count      : 4
Boot HART MIDELEG         : 0x0000000000003666
Boot HART MEDELEG         : 0x0000000000f0b509


U-Boot 2024.01-gd1308a36c (Nov 14 2025 - 14:57:10 +0800)

CPU:   rv64imafdcvh_zicbom_svpbmt_sstc_sscofpmf_ssaia_smaia_smstateen_ssstateen
Model: nuclei,evalsoc
DRAM:  2 GiB
Board: Initialized
Core:  18 devices, 13 uclasses, devicetree: board
MMC:   Nuclei SPI version 0xee010102
spi@10034000:mmc@0: 0
Loading Environment from nowhere... OK
In:    serial@10013000
Out:   serial@10013000
Err:   serial@10013000
Hit any key to stop autoboot:  0
=> setenv bootloc 6.12_rv64_hyp
=> boot
switch to partitions #0, OK
mmc0 is current device
Scanning mmc 0:1...
Found U-Boot script /boot.scr
725 bytes read in 263 ms (2 KiB/s)
## Executing script at 80200000
Boot images located in 6.12_rv64_hyp
Loading kernel: 6.12_rv64_hyp/uImage.lz4
4571990 bytes read in 17615 ms (252.9 KiB/s)
Loading ramdisk: 6.12_rv64_hyp/uInitrd.lz4
32971564 bytes read in 123923 ms (259.8 KiB/s)
6.12_rv64_hyp/kernel.dtb not found, ignore it
Starts booting from SD
## Booting kernel from Legacy Image at 83000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    4571926 Bytes = 4.4 MiB
   Load Address: 80400000
   Entry Point:  80400000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at 88300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    32971500 Bytes = 31.4 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at 88000000
   Booting using the fdt blob at 0x88000000
Working FDT set to 88000000
   Uncompressing Kernel Image
   Using Device Tree in place at 0000000088000000, end 00000000880055c2
Working FDT set to 88000000

Starting kernel ...

[    0.000000] Linux version 6.12.28+ (guibing@whml1.corp.nucleisys.com) (riscv64-unknown-linux-gnu-gcc (g553a166de) 14.2.1 20240816, GNU ld (GNU Binutils) 2.44) #3 SMP Mon Nov 17 23:23:02 CST 2025
[    0.000000] Machine model: nuclei,evalsoc
[    0.000000] SBI specification v1.0 detected
[    0.000000] SBI implementation ID=0x1 Version=0x10003
[    0.000000] SBI TIME extension detected
[    0.000000] SBI IPI extension detected
[    0.000000] SBI RFENCE extension detected
[    0.000000] SBI SRST extension detected
[    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
[    0.000000] printk: legacy bootconsole [sbi0] enabled
[    0.000000] efi: UEFI not found.
[    0.000000] OF: reserved mem: 0x0000000080000000..0x000000008003ffff (256 KiB) nomap non-reusable mmode_resv1@80000000
[    0.000000] OF: reserved mem: 0x0000000080040000..0x000000008005ffff (128 KiB) nomap non-reusable mmode_resv0@80040000
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000080000000-0x00000000fdffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000080000000-0x000000008005ffff]
[    0.000000]   node   0: [mem 0x0000000080060000-0x00000000fdffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000080000000-0x00000000fdffffff]
[    0.000000] SBI HSM extension detected
[    0.000000] CPU with hartid=1 is not available
[    0.000000] CPU with hartid=2 is not available
[    0.000000] CPU with hartid=3 is not available
[    0.000000] CPU with hartid=4 is not available
[    0.000000] CPU with hartid=5 is not available
[    0.000000] CPU with hartid=6 is not available
[    0.000000] CPU with hartid=7 is not available
[    0.000000] Falling back to deprecated "riscv,isa"
[    0.000000] riscv: base ISA extensions acdfhimv
[    0.000000] riscv: ELF capabilities acdfimv
[    0.000000] percpu: Embedded 17 pages/cpu s28824 r8192 d32616 u69632
[    0.000000] Kernel command line: earlycon=sbi console=ttyNUC0
[    0.000000] Dentry cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] Inode-cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 516096
[    0.000000] mem auto-init: stack:all(zero), heap alloc:off, heap free:off
[    0.000000] software IO TLB: SWIOTLB bounce buffer size adjusted to 1MB
[    0.000000] software IO TLB: area num 1.
[    0.000000] software IO TLB: mapped [mem 0x00000000fbf4b000-0x00000000fc14b000] (2MB)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=64 to nr_cpu_ids=1.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=1
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped using AIA
[    0.000000] riscv-imsic: interrupt-controller@4f200000: providing IPIs using interrupt 1
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000000] sched_clock: 64 bits at 33kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.008392] riscv-timer: Timer interrupt in S-mode is available via sstc extension
[    0.016937] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.026641] pid_max: default: 32768 minimum: 301
[    0.032653] Mount-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.039733] Mountpoint-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.090240] riscv: ELF compat mode unsupported
[    0.090454] ASID allocator using 16 bits (65536 entries)
[    0.101074] rcu: Hierarchical SRCU implementation.
[    0.105316] rcu:     Max phase no-delay instances is 1000.
[    0.114837] EFI services will not be available.
[    0.119812] smp: Bringing up secondary CPUs ...
[    0.124023] smp: Brought up 1 node, 1 CPU
[    0.128601] Memory: 1978532K/2064384K available (5284K kernel code, 4722K rwdata, 2048K rodata, 2153K init, 321K bss, 82492K reserved, 0K cma-reserved)
[    0.145507] devtmpfs: initialized
[    0.168609] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.178222] futex hash table entries: 256 (order: 2, 16384 bytes, linear)
[    0.185424] pinctrl core: initialized pinctrl subsystem
[    0.191040] DMI not present or invalid.
[    0.200988] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.210144] DMA: preallocated 256 KiB GFP_KERNEL pool for atomic allocations
[    0.217864] DMA: preallocated 256 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
[    0.285583] cpu0: Ratio of byte access time to unaligned word access is 1.40, unaligned accesses are fast
[    0.323120] pps_core: LinuxPPS API ver. 1 registered
[    0.327758] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.336883] PTP clock support registered
[    0.348052] clocksource: Switched to clocksource riscv_clocksource
[    0.368286] NET: Registered PF_INET protocol family
[    0.374999] IP idents hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    0.414703] tcp_listen_portaddr_hash hash table entries: 1024 (order: 2, 16384 bytes, linear)
[    0.423217] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.430633] TCP established hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    0.441101] TCP bind hash table entries: 16384 (order: 7, 524288 bytes, linear)
[    0.455810] TCP: Hash tables configured (established 16384 bind 16384)
[    0.462707] UDP hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    0.469726] UDP-Lite hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    0.478149] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    0.484680] kvm [1]: hypervisor extension available
[    0.489257] kvm [1]: using Sv48x4 G-stage page table format
[    0.494598] kvm [1]: VMID 14 bits available
[    0.498901] kvm [1]: AIA available with 3 guest external interrupts
[    0.510498] Trying to unpack rootfs image as initramfs...
[    1.528320] workingset: timestamp_bits=62 max_order=19 bucket_order=0
[    1.538482] 9p: Installing v9fs 9p2000 file system support
[    2.682586] NET: Registered PF_ALG protocol family
[    2.687347] io scheduler mq-deadline registered
[    2.691558] io scheduler kyber registered
[    2.695709] io scheduler bfq registered
[    3.963897] riscv-imsic: interrupt-controller@4f200000:  hart-index-bits: 0,  guest-index-bits: 2
[    3.972656] riscv-imsic: interrupt-controller@4f200000: group-index-bits: 0, group-index-shift: 24
[    3.981414] riscv-imsic: interrupt-controller@4f200000: per-CPU IDs 255 at base address 0x000000004f200000
[    3.991149] riscv-imsic: interrupt-controller@4f200000: total 254 interrupts available
[    7.051086] brd: module loaded
[    7.130432] loop: module loaded
[    7.168701] NET: Registered PF_INET6 protocol family
[    7.194915] Segment Routing with IPv6
[    7.198822] In-situ OAM (IOAM) with IPv6
[    7.203063] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[    7.214477] NET: Registered PF_PACKET protocol family
[    7.248779] 9pnet: Installing 9P2000 support
[    7.349426] riscv-aplic 10044000.interrupt-controller: 31 interrupts forwarded to MSI base 0x000000004f200000
[    7.364013] 10013000.serial: ttyNUC0 at MMIO 0x10013000 (irq = 11, base_baud = 3125000) is a Nuclei UART v0
[    7.373596] printk: legacy console [ttyNUC0] enabled
[    7.373596] printk: legacy console [ttyNUC0] enabled
[    7.383209] printk: legacy bootconsole [sbi0] disabled
[    7.383209] printk: legacy bootconsole [sbi0] disabled
[    8.273101] nuclei_spi 10014000.spi: mapped; irq=13, cs=4
[   13.447631] Freeing initrd memory: 32192K
[   13.493530] ftl_cs: FTL header not found.
[   13.506439] nuclei_spi 10034000.spi: mapped; irq=14, cs=4
[   13.558471] mmc_spi spi1.0: SD/MMC host mmc0, no WP, no poweroff, cd polling
[   13.567657] clk: Disabling unused clocks
[   13.587341] Freeing unused kernel image (initmem) memory: 2152K
[   13.593017] Run /init as init process
[   13.712341] mmc0: host does not support reading read-only switch, assuming write-enable
[   13.720123] mmc0: new SDHC card on SPI
[   13.740966] mmcblk0: mmc0:0000 SD32G 29.7 GiB
[   13.806549]  mmcblk0: p1
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
[   24.836669] random: crng init done
ssh-keygen: generating new host keys: RSA ECDSA ED25519
Starting sshd: OK

Welcome to Nuclei System Technology
nucleisys login: root
Password:
# mount /dev/mmcblk0p1 /mnt/
[   73.610626] FAT-fs (mmcblk0p1): Volume was not properly unmounted. Some data may be corrupt. Please run fsck.
# qemu-system-riscv64 -M virt,aia=aplic-imsic --enable-kvm -m 1.5G -smp 4 -nographic -kernel /mnt/Image_6.10 -initrd /mnt/rootfs.img -virtfs local,path=/mnt/,mount_tag=host_share,security_model=none
qemu-system-riscv64: warning: Number of SMP cpus requested (4) exceeds the recommended                                                                       cpus supported by KVM (1)
qemu-system-riscv64: warning: Number of hotpluggable cpus requested (4) exceeds the rec                                                                      ommended cpus supported by KVM (1)
KVM AIA: default mode is auto
[    0.000000] Linux version 6.10.14 (guibing@whml1.corp.nucleisys.com) (riscv64-unknown-linux-gnu-gcc (g553a166de) 14.2.1 20240816, GNU ld (GNU Binutils) 2.44) #4 SMP Fri May 30 10:21:01 CST 2025
[    0.000000] random: crng init done
[    0.000000] Machine model: riscv-virtio,qemu
[    0.000000] SBI specification v2.0 detected
[    0.000000] SBI implementation ID=0x3 Version=0x60c1c
[    0.000000] SBI TIME extension detected
[    0.000000] SBI IPI extension detected
[    0.000000] SBI RFENCE extension detected
[    0.000000] SBI SRST extension detected
[    0.000000] efi: UEFI not found.
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000080000000-0x00000000dfffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000080000000-0x00000000dfffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000080000000-0x00000000dfffffff]
[    0.000000] SBI HSM extension detected
[    0.000000] riscv: base ISA extensions acdfimv
[    0.000000] riscv: ELF capabilities acdfimv
[    0.000000] percpu: Embedded 22 pages/cpu s49720 r8192 d32200 u90112
[    0.000000] Kernel command line:
[    0.000000] Dentry cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] Inode-cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 393216
[    0.000000] mem auto-init: stack:all(zero), heap alloc:off, heap free:off
[    0.000000] software IO TLB: SWIOTLB bounce buffer size adjusted to 1MB
[    0.000000] software IO TLB: area num 4.
[    0.000000] software IO TLB: SWIOTLB bounce buffer size roundup to 2MB
[    0.000000] software IO TLB: mapped [mem 0x00000000dd200000-0x00000000dd400000] (2MB)
[    0.000000] Virtual kernel memory layout:
[    0.000000]       fixmap : 0xffff8d7ffea00000 - 0xffff8d7fff000000   (6144 kB)
[    0.000000]       pci io : 0xffff8d7fff000000 - 0xffff8d8000000000   (  16 MB)
[    0.000000]      vmemmap : 0xffff8d8000000000 - 0xffff8f8000000000   (2048 GB)
[    0.000000]      vmalloc : 0xffff8f8000000000 - 0xffffaf8000000000   (  32 TB)
[    0.000000]      modules : 0xffffffff01597000 - 0xffffffff80000000   (2026 MB)
[    0.000000]       lowmem : 0xffffaf8000000000 - 0xffffaf8060000000   (1536 MB)
[    0.000000]       kernel : 0xffffffff80000000 - 0xffffffffffffffff   (2047 MB)
[    0.000000] Memory: 1502772K/1572864K available (10142K kernel code, 4979K rwdata, 4096K rodata, 2254K init, 532K bss, 70092K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=4, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=64 to nr_cpu_ids=4.
[    0.000000] rcu:     RCU debug extended QS entry/exit.
[    0.000000]  Tracing variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 25 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=4
[    0.000000] RCU Tasks Trace: Setting shift to 2 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=4.
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped using AIA
[    0.000000] imsic_local_init line445
[    0.000000]  nr_ids:255
[    0.000000] imsic_local_init line445
[    0.000000]  nr_ids:255
[    0.000000] imsic_local_init line445
[    0.000000]  nr_ids:255
[    0.000000] imsic_local_init line445
[    0.000000]  nr_ids:255
[    0.000000] riscv-imsic: imsics@28000000: providing IPIs using interrupt 1
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000030] sched_clock: 64 bits at 33kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.000244] riscv-timer: Timer interrupt in S-mode is available via sstc extension
[    0.014739] Console: colour dummy device 80x25
[    0.015380] printk: legacy console [tty0] enabled
[    0.023529] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=131)
[    0.023956] pid_max: default: 32768 minimum: 301
[    0.026184] LSM: initializing lsm=capability
[    0.031311] Mount-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.033264] Mountpoint-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.115783] riscv: ELF compat mode unsupported
[    0.117645] ASID allocator using 16 bits (65536 entries)
[    0.122955] rcu: Hierarchical SRCU implementation.
[    0.123474] rcu:     Max phase no-delay instances is 1000.
[    0.138580] EFI services will not be available.
[    0.150390] smp: Bringing up secondary CPUs ...
[    0.254486] smp: Brought up 1 node, 4 CPUs
[    0.505004] devtmpfs: initialized
[    0.598632] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645041785100000 ns
[    0.599243] futex hash table entries: 1024 (order: 4, 65536 bytes, linear)
[    0.608734] pinctrl core: initialized pinctrl subsystem
[    0.650787] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.706451] DMA: preallocated 256 KiB GFP_KERNEL pool for atomic allocations
[    0.724487] DMA: preallocated 256 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
[    0.725921] audit: initializing netlink subsys (disabled)
[    0.774383] audit: type=2000 audit(0.480:1): state=initialized audit_enabled=0 res=1
[    0.781402] thermal_sys: Registered thermal governor 'step_wise'
[    0.782257] cpuidle: using governor menu
[    0.963409] cpu1: Ratio of byte access time to unaligned word access is 1.40, unaligned accesses are fast
[    0.964477] cpu3: Ratio of byte access time to unaligned word access is 1.40, unaligned accesses are fast
[    0.965362] cpu2: Ratio of byte access time to unaligned word access is 1.40, unaligned accesses are fast
[    0.992584] cpu0: Ratio of byte access time to unaligned word access is 1.40, unaligned accesses are fast
[    1.278106] HugeTLB: registered 2.00 MiB page size, pre-allocated 0 pages
[    1.278472] HugeTLB: 28 KiB vmemmap can be freed for a 2.00 MiB page
[    1.345703] ACPI: Interpreter disabled.
[    1.349914] iommu: Default domain type: Translated
[    1.350189] iommu: DMA domain TLB invalidation policy: strict mode
[    1.372894] SCSI subsystem initialized
[    1.421997] usbcore: registered new interface driver usbfs
[    1.425750] usbcore: registered new interface driver hub
[    1.427581] usbcore: registered new device driver usb
[    1.441650] Advanced Linux Sound Architecture Driver Initialized.
[    1.485290] vgaarb: loaded
[    1.634735] clocksource: Switched to clocksource riscv_clocksource
[    1.664459] pnp: PnP ACPI: disabled
[    1.978668] NET: Registered PF_INET protocol family
[    2.000244] IP idents hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    2.057189] tcp_listen_portaddr_hash hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    2.059417] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    2.061309] TCP established hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    2.070831] TCP bind hash table entries: 16384 (order: 8, 1048576 bytes, linear)
[    2.142120] TCP: Hash tables configured (established 16384 bind 16384)
[    2.153625] UDP hash table entries: 1024 (order: 4, 98304 bytes, linear)
[    2.160247] UDP-Lite hash table entries: 1024 (order: 4, 98304 bytes, linear)
[    2.175689] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    2.281768] RPC: Registered named UNIX socket transport module.
[    2.282165] RPC: Registered udp transport module.
[    2.282348] RPC: Registered tcp transport module.
[    2.284149] RPC: Registered tcp-with-tls transport module.
[    2.284423] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    2.284729] PCI: CLS 0 bytes, default 64
[    2.317230] Unpacking initramfs...
[    2.395690] workingset: timestamp_bits=46 max_order=19 bucket_order=0
[    2.547729] NFS: Registering the id_resolver key type
[    2.548645] Key type id_resolver registered
[    2.548889] Key type id_legacy registered
[    2.549804] nfs4filelayout_init: NFSv4 File Layout Driver Registering...
[    2.550567] nfs4flexfilelayout_init: NFSv4 Flexfile Layout Driver Registering...
[    2.567962] 9p: Installing v9fs 9p2000 file system support
[    2.586578] NET: Registered PF_ALG protocol family
[    2.588745] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 245)
[    2.589233] io scheduler mq-deadline registered
[    2.589508] io scheduler kyber registered
[    2.590087] io scheduler bfq registered
[    2.814361] riscv-imsic: imsics@28000000:  hart-index-bits: 2,  guest-index-bits: 0
[    2.814758] riscv-imsic: imsics@28000000: group-index-bits: 0, group-index-shift: 24
[    2.815002] riscv-imsic: imsics@28000000: per-CPU IDs 255 at base PPN 0x0000000028000000
[    2.815277] riscv-imsic: imsics@28000000: total 1016 interrupts available
[    2.938995] SBI CPPC extension NOT detected!!
[    5.882812] Freeing initrd memory: 1024K
[    6.756347] Serial: 8250/16550 driver, 4 ports, IRQ sharing disabled
[    6.813415] SuperH (H)SCI(F) driver initialized
[    7.032928] loop: module loaded
[    7.098114] e1000e: Intel(R) PRO/1000 Network Driver
[    7.098632] e1000e: Copyright(c) 1999 - 2015 Intel Corporation.
[    7.154113] usbcore: registered new interface driver uas
[    7.155670] usbcore: registered new interface driver usb-storage
[    7.160552] mousedev: PS/2 mouse device common for all mice
[    7.215881] sdhci: Secure Digital Host Controller Interface driver
[    7.216217] sdhci: Copyright(c) Pierre Ossman
[    7.220581] Synopsys Designware Multimedia Card Interface Driver
[    7.228729] sdhci-pltfm: SDHCI platform and OF driver helper
[    7.238006] usbcore: registered new interface driver usbhid
[    7.238372] usbhid: USB HID core driver
[    7.277893] NET: Registered PF_INET6 protocol family
[    7.400970] Segment Routing with IPv6
[    7.415618] In-situ OAM (IOAM) with IPv6
[    7.417663] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[    7.469268] NET: Registered PF_PACKET protocol family
[    7.472442] 9pnet: Installing 9P2000 support
[    7.487701] Key type dns_resolver registered
[    7.763427] hrtimer: interrupt took 100494385 ns
[    8.046142] Timer migration: 1 hierarchy levels; 8 children per group; 1 crossnode level
[    8.769226] debug_vm_pgtable: [debug_vm_pgtable         ]: Validating architecture page table helpers
[    8.802368] riscv-aplic d000000.aplic: 96 interrupts forwarded to MSI base 0x0000000028000000
[    8.822418] pci-host-generic 30000000.pci: host bridge /soc/pci@30000000 ranges:
[    8.839996] pci-host-generic 30000000.pci:       IO 0x0003000000..0x000300ffff -> 0x0000000000
[    8.841186] pci-host-generic 30000000.pci:      MEM 0x0040000000..0x007fffffff -> 0x0040000000
[    8.841674] pci-host-generic 30000000.pci:      MEM 0x0400000000..0x07ffffffff -> 0x0400000000
[    8.855865] pci-host-generic 30000000.pci: Memory resource size exceeds max for 32 bits
[    8.859344] pci-host-generic 30000000.pci: ECAM at [mem 0x30000000-0x3fffffff] for [bus 00-ff]
[    8.867767] pci-host-generic 30000000.pci: PCI host bridge to bus 0000:00
[    8.868194] pci_bus 0000:00: root bus resource [bus 00-ff]
[    8.868438] pci_bus 0000:00: root bus resource [io  0x0000-0xffff]
[    8.868682] pci_bus 0000:00: root bus resource [mem 0x40000000-0x7fffffff]
[    8.868927] pci_bus 0000:00: root bus resource [mem 0x400000000-0x7ffffffff]
[    8.871032] pci 0000:00:00.0: [1b36:0008] type 00 class 0x060000 conventional PCI endpoint
[    8.890808] pci 0000:00:01.0: [1af4:1009] type 00 class 0x000200 conventional PCI endpoint
[    8.892791] pci 0000:00:01.0: BAR 0 [io  0x0000-0x003f]
[    8.897003] pci 0000:00:01.0: BAR 1 [mem 0x00000000-0x00000fff]
[    8.899688] pci 0000:00:01.0: BAR 4 [mem 0x00000000-0x00003fff 64bit pref]
[    8.927062] pci 0000:00:01.0: BAR 4 [mem 0x400000000-0x400003fff 64bit pref]: assigned
[    8.928558] pci 0000:00:01.0: BAR 1 [mem 0x40000000-0x40000fff]: assigned
[    8.929168] pci 0000:00:01.0: BAR 0 [io  0x0040-0x007f]: assigned
[    8.938690] virtio-pci 0000:00:01.0: enabling device (0000 -> 0003)
[    9.040771] msi_domain_activate,line669
[    9.041107] imsic_irq_compose_vector_msg addr:0-28001000,data:2
[    9.051727] msi_domain_activate,line669
[    9.052062] imsic_irq_compose_vector_msg addr:0-28002000,data:2
[    9.342163] 10000000.serial: ttyS0 at MMIO 0x10000000 (irq = 14, base_baud = 230400) is a 16550A
[    9.346282] printk: legacy console [ttyS0] enabled
[   20.096008] msi_domain_activate,line669
[   20.117919] imsic_irq_compose_vector_msg addr:0-28000000,data:3
[   20.241699] goldfish_rtc 101000.rtc: registered as rtc0
[   20.334716] goldfish_rtc 101000.rtc: setting system clock to 1970-01-01T00:04:30 UTC (270)
[   20.400939] Legacy PMU implementation is available
[   20.447235] clk: Disabling unused clocks
[   20.484405] PM: genpd: Disabling unused power domains
[   20.514038] ALSA device list:
[   20.530334]   No soundcards found.
[   20.560516] msi_domain_activate,line669
[   20.581146] imsic_irq_compose_vector_msg addr:0-28003000,data:2
[   20.721282] Freeing unused kernel image (initmem) memory: 2252K
[   20.759155] Run /init as init process
           _  _
          | ||_|
          | | _ ____  _   _  _  _
          | || |  _ \| | | |\ \/ /
          | || | | | | |_| |/    \
          |_||_|_| |_|\____|\_/\_/

               Busybox Rootfs

Please press Enter to activate this console.
/ # uname -a
Linux (none) 6.10.14 #4 SMP Fri May 30 10:21:01 CST 2025 riscv64 GNU/Linux
/ # cat /proc/cpuinfo
processor       : 0
hart            : 0
isa             : rv64imafdcv_zicbom_zicntr_zicsr_zifencei_zihpm_smstateen_ssaia_sstc_svpbmt
mmu             : sv48
mvendorid       : 0x536
marchid         : 0x1000
mimpid          : 0x10300
hart isa        : rv64imafdcv_zicbom_zicntr_zicsr_zifencei_zihpm_smstateen_ssaia_sstc_svpbmt

processor       : 1
hart            : 1
isa             : rv64imafdcv_zicbom_zicntr_zicsr_zifencei_zihpm_smstateen_ssaia_sstc_svpbmt
mmu             : sv48
mvendorid       : 0x536
marchid         : 0x1000
mimpid          : 0x10300
hart isa        : rv64imafdcv_zicbom_zicntr_zicsr_zifencei_zihpm_smstateen_ssaia_sstc_svpbmt

processor       : 2
hart            : 2
isa             : rv64imafdcv_zicbom_zicntr_zicsr_zifencei_zihpm_smstateen_ssaia_sstc_svpbmt
mmu             : sv48
mvendorid       : 0x536
marchid         : 0x1000
mimpid          : 0x10300
hart isa        : rv64imafdcv_zicbom_zicntr_zicsr_zifencei_zihpm_smstateen_ssaia_sstc_svpbmt

processor       : 3
hart            : 3
isa             : rv64imafdcv_zicbom_zicntr_zicsr_zifencei_zihpm_smstateen_ssaia_sstc_svpbmt
mmu             : sv48
mvendorid       : 0x536
marchid         : 0x1000
mimpid          : 0x10300
hart isa        : rv64imafdcv_zicbom_zicntr_zicsr_zifencei_zihpm_smstateen_ssaia_sstc_svpbmt

/ # mkdir -p /fromhost
/ # mount -t 9p -o trans=virtio host_share /fromhost
/ # cd /fromhost/

```

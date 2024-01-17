# XEC User Guide

## 1.XEC Introduce

XEC is a high performance 1000M/100M/10M Ethernet Controller IP. 
It support GMII/RGMII/MII/RMII MAC-PHY interface and support AXI/AHB system bus.
More info please refer to XEC IP doc.

## 2. How To Use Linux XEC Driver.

Draft XEC Driver is developed on FPGA Platform. PHY using Fixmode not autoneg mode,10Mbps, Full-Duplex. Linux version is 6.1, Other Linux version can also refer to this doc.

### 2.1. Hardware Requirements

1. The XEC driver descriptors 
	It needs to be stored in non-cacheable readable and writable memory space, so the chip needs to have a way to provide such space.

	For example, the non-cachable space could be DLM or Device Memory by mattrib csr or riscv svpbmt feature.

2. The XEC driver tx/rx buffer

	It needs a mechanism to maintain buffer coherent between cpu and XEC hardware, such as riscv cmo feature or nuclei ccm feature.

3. Cpu core compatibility

	If the cpu core have **no svpbmt extension**, you can use nuclei custom mattrib csr to construct a ddr memory space as noncachable area or DLM directly.

	if the cpu core have **no zicbom extension**, you can use nuclei custom ccm csr to flush cache to maintain data coherent between cpu and xec. if you want to use ccm to flush cache, you need to porting linux/arch/riscv/mm/dma-noncoherent.c using ccm.

	*Linux kernel v6.1 have no ccm porting, using zicbom.*

### 2.2. DTS Configure

1. Add "dma-noncoherent" to dts root node.

```
/ {
  #address-cells = <2>;
  #size-cells = <2>;
  compatible = "nuclei,customsoc";
  model = "nuclei,customsoc";
  dma-noncoherent;
  chosen {
      bootargs = "earlycon=sbi console=ttyNUC0";
      stdout-path = "serial0";
  };

  aliases {
    serial0 = &uart0;
  };
```

2. Add xec dts node

```
  xec0: xec@f8b160000 {
    compatible = "nuclei,xec";
    reg = <0xf 0x8b160000 0x0 0x1000>;
    desc_mem = <0xf 0x88010000>; --> according to riscv extension to decide if need to add this prop.
    interrupt-parent = <&plic0>;
    interrupts = <13>;
    clocks = <&clkc 2>, <&clkc 23>;
    local-mac-address = [00 2b 20 21 03 23];
    phy-handle = <&rtl8211f>;
    phy-mode = "rgmii";

    mdio {
        compatible = "snps,dwmac-mdio";
        #address-cells = <1>;
        #size-cells = <0>;

        rtl8211f: ethernet-phy@2 { -->PHY address is decided by PCB
            compatible = "ethernet-phy-ieee802.3-c22";
            reg = <2>;
        };
    };
```

3. Different extension case

	if core have svpbmt && zicbom extension, modify cpu dts node
	```
	cpus {
		#address-cells = <1>;
		#size-cells = <0>;
		timebase-frequency = <TIMERCLK_FREQ>;
		cpu0: cpu@0 {
			device_type = "cpu";
			reg = <0>;
			status = "okay";
			compatible = "riscv";

			riscv,isa = "rv64imafdc_zicbom_svpbmt";
			riscv,cbom-block-size =<64>;
			mmu-type = "riscv,sv39";
			clock-frequency = <CPUCLK_FREQ>;
			cpu0_intc: interrupt-controller {
				#interrupt-cells = <1>;
				interrupt-controller;
				compatible = "riscv,cpu-intc";
			};
		};
	};

	```
	**if core have no svpbmt extension, you must not add svpbmt to riscv,isa node**.
	if core have no svpbmt extension, you can assigned the non-cachable address to desc_mem.

	**Example1**: using DLM as non-cachable area.
	DLM base address is 0xf88010000 
	```
	desc_mem = <0xf 0x88010000>;
	```

	**Example2**: using Nuclei mattrib csr to make Device memory as non-cachable area.
	set 0x3e000000~0x3effffff as non-cachable area.(Must set mattrib in M-mode.)
	```
	#define mattri0_base 0x7f3
	#define mattri0_mask 0x7f4
	csr_write(mattri0_mask, 0xfff000000);
	csr_write(mattri0_base, 0x3e000002);
	```
	mattrib detail usage please refer to Nuclei_RISC-V_ISA_Spec


### 2.3. Linux Kernel

If use svpbmt and zicbom,you should choose following config:

```
	CONFIG_RISCV_ISA_SVPBMT=y
	CONFIG_RISCV_ISA_ZICBOM=y
```

If GCC toolchain version is old, maybe above config cannot be selected. because those config depend on new GCC version.

GCC13 toolchain can select above config. Nuclei Linux sdk toolchain is config by buildroot config file, such as conf/customsoc/buildroot_initramfs_rv64imafdc_config

xec driver config:

```
CONFIG_NUCLEI_XEC=y
```

## 3. Related Files

1. Linux XEC driver path:

```
linux/drivers/net/ethernet/nuclei/
├── Kconfig
├── Makefile
└── xec.c
```

During development, our bitfile system clk is 10Mhz, so we set xec div to 4 in opensbi temporarily, to require xec_clk is 2.5M.

2. DTS path:

conf/customsoc/nuclei_rv64imafdc.dts

conf/customsoc/nuclei_rv64imafdc.dts

3. Linux kernel config path:

conf/customsoc/linux_rv64imafdc_defconfig

conf/customsoc/linux_rv64imafdc_defconfig

## 4. How to test xec

1. config PHY
> ethtool -s eth0 speed 10 duplex full autoneg off

2. allocate ip address

3. ping cmd to test network

```
OpenSBI v1.3
Build time: 2024-01-17 12:52:36 +0800
Build compiler: gcc version 13.1.1 20230713 (g598f284ab)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|___/_____|
        | |
        |_|

Platform Name             : nuclei,customsoc
Platform Features         : medeleg
Platform HART Count       : 1
Platform IPI Device       : aclint-mswi
Platform Timer Device     : aclint-mtimer @ 10000000Hz
Platform Console Device   : nuclei_uart
Platform HSM Device       : ---
Platform PMU Device       : ---
Platform Reboot Device    : ---
Platform Shutdown Device  : ---
Platform Suspend Device   : ---
Platform CPPC Device      : ---
Firmware Base             : 0x0
Firmware Size             : 322 KB
Firmware RW Offset        : 0x40000
Firmware RW Size          : 66 KB
Firmware Heap Offset      : 0x48000
Firmware Heap Size        : 34 KB (total), 2 KB (reserved), 9 KB (used), 22 KB (free)
Firmware Scratch Size     : 4096 B (total), 760 B (used), 3336 B (free)
Runtime SBI Version       : 1.0

Domain0 Name              : root
Domain0 Boot HART         : 0
Domain0 HARTs             : 0*
Domain0 Region00          : 0x0000000f80031000-0x0000000f80031fff M: (I,R,W) S/U: ()
Domain0 Region01          : 0x0000000f80040000-0x0000000f80040fff M: (I,R,W) S/U: ()
Domain0 Region02          : 0x0000000f80032000-0x0000000f80033fff M: (I,R,W) S/U: ()
Domain0 Region03          : 0x0000000f80034000-0x0000000f80037fff M: (I,R,W) S/U: ()
Domain0 Region04          : 0x0000000f80038000-0x0000000f8003ffff M: (I,R,W) S/U: ()
Domain0 Region05          : 0x0000000000040000-0x000000000005ffff M: (R,W) S/U: ()
Domain0 Region06          : 0x0000000000000000-0x000000000003ffff M: (R,X) S/U: ()
Domain0 Region07          : 0x0000000000000000-0xffffffffffffffff M: (R,W,X) S/U: (R,W,X)
Domain0 Next Address      : 0x0000000000200000
Domain0 Next Arg1         : 0x0000000008000000
Domain0 Next Mode         : S-mode
Domain0 SysReset          : yes
Domain0 SysSuspend        : yes

Boot HART ID              : 0
Boot HART Domain          : root
Boot HART Priv Version    : v1.12
Boot HART Base ISA        : rv64imafdcbpvk
Boot HART ISA Extensions  : sscofpmf,time,sstc
Boot HART PMP Count       : 8
Boot HART PMP Granularity : 4096
Boot HART PMP Address Bits: 34
Boot HART MHPM Count      : 4
Boot HART MIDELEG         : 0x0000000000002222
Boot HART MEDELEG         : 0x000000000000b109


U-Boot 2023.10-00008-g0e6bf73c45 (Jan 17 2024 - 12:52:36 +0800)

CPU:   rv64imafdc_zicbom_svpbmt
Model: nuclei,customsoc
DRAM:  992 MiB
Board: Initialized
Core:  17 devices, 10 uclasses, devicetree: board
MMC:
Loading Environment from nowhere... OK
In:    serial@f8b110000
Out:   serial@f8b110000
Err:   serial@f8b110000
Hit any key to stop autoboot:  0
## Booting kernel from Legacy Image at 03000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    4430549 Bytes = 4.2 MiB
   Load Address: 00400000
   Entry Point:  00400000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at 08300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    6785854 Bytes = 6.5 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at 08000000
   Booting using the fdt blob at 0x8000000
Working FDT set to 8000000
   Uncompressing Kernel Image
   Using Device Tree in place at 0000000008000000, end 0000000008004603
Working FDT set to 8000000

Starting kernel ...

[    0.000000] Linux version 6.6.7+ (guibing@whml1.corp.nucleisys.com) (riscv64-unknown-linux-gnu-gcc (g598f284ab) 13.1.1 20230713, GNU ld (GNU Binutils) 2.40.0.20230314) #4 Wed Jan 17 12:52:07 CST 2024
[    0.000000] Machine model: nuclei,customsoc
[    0.000000] SBI specification v1.0 detected
[    0.000000] SBI implementation ID=0x1 Version=0x10003
[    0.000000] SBI TIME extension detected
[    0.000000] SBI IPI extension detected
[    0.000000] SBI RFENCE extension detected
[    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
[    0.000000] printk: bootconsole [sbi0] enabled
[    0.000000] efi: UEFI not found.
[    0.000000] OF: reserved mem: 0x0000000000000000..0x000000000003ffff (256 KiB) nomap non-reusable mmode_resv1@0
[    0.000000] OF: reserved mem: 0x0000000000040000..0x000000000005ffff (128 KiB) nomap non-reusable mmode_resv0@40000
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000000000000-0x000000003dffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000000000000-0x000000000005ffff]
[    0.000000]   node   0: [mem 0x0000000000060000-0x000000003dffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000000000000-0x000000003dffffff]
[    0.000000] Falling back to deprecated "riscv,isa"
[    0.000000] riscv: base ISA extensions acdfim
[    0.000000] riscv: ELF capabilities acdfim
[    0.000000] Kernel command line: earlycon=sbi console=ttyNUC0 clk_ignore_unused
[    0.000000] Dentry cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] Inode-cache hash table entries: 65536 (order: 7, 524288 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 250480
[    0.000000] mem auto-init: stack:all(zero), heap alloc:off, heap free:off
[    0.000000] Memory: 976896K/1015808K available (5115K kernel code, 4770K rwdata, 2048K rodata, 2109K init, 301K bss, 38912K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped
[    0.000000] plic: interrupt-controller@f84000000: mapped 31 interrupts with 1 handlers for 2 contexts.
[    0.000000] nuclei_clk_setup: nuclei clock init
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x24e6a1710, max_idle_ns: 440795202120 ns
[    0.000052] sched_clock: 64 bits at 10MHz, resolution 100ns, wraps every 4398046511100ns
[    0.012414] Calibrating delay loop (skipped), value calculated using timer frequency.. 20.00 BogoMIPS (lpj=100000)
[    0.023144] pid_max: default: 32768 minimum: 301
[    0.034881] Mount-cache hash table entries: 2048 (order: 2, 16384 bytes, linear)
[    0.042220] Mountpoint-cache hash table entries: 2048 (order: 2, 16384 bytes, linear)
[    0.124939] riscv: ELF compat mode supported
[    0.126013] ASID allocator using 16 bits (65536 entries)
[    0.142568] EFI services will not be available.
[    0.166828] devtmpfs: initialized
[    0.281475] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.291713] futex hash table entries: 256 (order: 0, 6144 bytes, linear)
[    0.300812] pinctrl core: initialized pinctrl subsystem
[    0.357849] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.375770] DMA: preallocated 128 KiB GFP_KERNEL pool for atomic allocations
[    0.385777] DMA: preallocated 128 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
[    0.489643] cpu0: Ratio of byte access time to unaligned word access is 0.16, unaligned accesses are slow
[    0.601065] platform f8b250000.display-controller: Fixed dependency cycle(s) with /panel-rgb/port/endpoint
[    0.704336] pps_core: LinuxPPS API ver. 1 registered
[    0.709319] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.718605] PTP clock support registered
[    0.771854] clocksource: Switched to clocksource riscv_clocksource
[    0.873387] NET: Registered PF_INET protocol family
[    0.890696] IP idents hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    1.043004] tcp_listen_portaddr_hash hash table entries: 512 (order: 0, 4096 bytes, linear)
[    1.051643] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    1.059518] TCP established hash table entries: 8192 (order: 4, 65536 bytes, linear)
[    1.075010] TCP bind hash table entries: 8192 (order: 5, 131072 bytes, linear)
[    1.095637] TCP: Hash tables configured (established 8192 bind 8192)
[    1.106506] UDP hash table entries: 512 (order: 2, 16384 bytes, linear)
[    1.114954] UDP-Lite hash table entries: 512 (order: 2, 16384 bytes, linear)
[    1.129797] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    1.163597] RPC: Registered named UNIX socket transport module.
[    1.168975] RPC: Registered udp transport module.
[    1.173925] RPC: Registered tcp transport module.
[    1.178055] RPC: Registered tcp-with-tls transport module.
[    1.183698] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    1.237715] workingset: timestamp_bits=62 max_order=18 bucket_order=0
[    1.276268] Trying to unpack rootfs image as initramfs...
[    1.310185] jffs2: version 2.2. (NAND) © 2001-2006 Red Hat, Inc.
[    9.332974] JFS: nTxBlock = 7632, nTxLock = 61056
[    9.560811] NET: Registered PF_ALG protocol family
[    9.568106] io scheduler mq-deadline registered
[    9.572489] io scheduler kyber registered
[    9.577028] io scheduler bfq registered
[   21.868690] f8b110000.serial: ttyNUC0 at MMIO 0xf8b110000 (irq = 2, base_baud = 625000) is a Nuclei UART v0
[   21.879447] printk: console [ttyNUC0] enabled
[   21.879447] printk: console [ttyNUC0] enabled
[   21.887378] printk: bootconsole [sbi0] disabled
[   21.887378] printk: bootconsole [sbi0] disabled
[   22.948198] brd: module loaded
[   23.489083] loop: module loaded
[   24.136907] Freeing initrd memory: 6620K
[   24.458718] nuclei-xec f8b160000.xec eth0: using RGMII interface
[   24.498956] Generic PHY f8b160000.xec-ffffffff:02: attached PHY driver (mii_bus:phy_addr=f8b160000.xec-ffffffff:02, irq=POLL)
[   24.510243] nuclei-xec f8b160000.xec eth0: XEC mac at 0xf8b160000 irq 3
[   24.577988] NET: Registered PF_INET6 protocol family
[   24.656318] Segment Routing with IPv6
[   24.663609] In-situ OAM (IOAM) with IPv6
[   24.672539] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[   24.719272] NET: Registered PF_PACKET protocol family
[   25.315652] clk: Not disabling unused clocks
[   25.400860] Freeing unused kernel image (initmem) memory: 2108K
[   25.408133] Run /init as init process
Saving 256 bits of non-creditable seed for next boot
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory

Welcome to Nuclei System Technology
nucleisys login: root
Password:
#
# ethtool -s eth0 speed 10 duplex full autoneg off
# udhcpc
udhcpc: started, v1.36.1
udhcpc: broadcasting discover
udhcpc: broadcasting select for 192.168.40.171, server 192.168.40.1
udhcpc: lease of 192.168.40.171 obtained from 192.168.40.1, lease time 7200
deleting routers
adding dns 192.168.55.101
adding dns 192.168.55.102
adding dns 192.168.55.105
# ping www.baidu.com
PING www.baidu.com (183.2.172.185): 56 data bytes
64 bytes from 183.2.172.185: seq=0 ttl=49 time=29.372 ms
64 bytes from 183.2.172.185: seq=1 ttl=49 time=25.462 ms
64 bytes from 183.2.172.185: seq=2 ttl=49 time=26.487 ms
^C
--- www.baidu.com ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 25.462/27.107/29.372 ms
#
```

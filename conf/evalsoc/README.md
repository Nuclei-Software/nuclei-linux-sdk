# Android porting on Nuclei Platform

## 1.build linux sdk

### 1.1 download & build Nuclei Linux SDK for android

currently only `CORE=ux900fd` can work，other CORE configure is not verified.

```shell
$git clone git@github.com:Nuclei-Software/nuclei-linux-sdk.git -b dev_nuclei_6.6_v2_android
$cd nuclei-linux-sdk
$make SOC=evalsoc CORE=ux900fd BOOT_MODE=sd freeloader -j32
$make SOC=evalsoc CORE=ux900fd BOOT_MODE=sd bootimages -j32
```

output image:
```shell
nuclei-linux-sdk$ ls work/evalsoc/boot/
boot.scr  kernel.dtb  uImage.lz4  uInitrd.lz4
```
here boot.scr and uImage.lz4 are used for Android boot, uInitrd.lz4 is not for android, need Android
output image ramdisk to generate new uInitrd.lz4.

## 2.build android

### 2.1. download sourcecode

detail info refer to [download android](https://source.android.google.cn/docs/setup/download/downloading?hl=zh-cn)

```shell
$mkdir aosp_prj
$cd aosp_prj
$repo init -u https://android.googlesource.com/platform/manifest -b main
$repo sync -c -j8
```

if google repo sync cannot success,you can try tuna repo, please refer to https://mirrors.tuna.tsinghua.edu.cn/help/AOSP/

### 2.2. patch sourcecode

```shell
$git clone git@github.com:Nuclei-Software/aosp_device_nuclei_fpga.git
$mkdir -p aosp_prj/device/nuclei/fpga
$cp -rf aosp_device_nuclei_fpga/* aosp_prj/device/nuclei/fpga/
$git clone git@github.com:Nuclei-Software/aosp_hardware_nuclei.git
$mkdir -p aosp_prj/hardware/nuclei
$cp -rf aosp_hardware_nuclei/* aosp_prj/hardware/nuclei/
```

### 2.3. build android image

```shell
$cd aosp_prj
$source build/envsetup.sh
$lunch fpga-trunk-eng
$make ramdisk systemimage vendorimage -j8
```

build output image:
```
aosp_prj/out/target/product/fpga/ramdisk.img
aosp_prj/out/target/product/fpga/system.img
aosp_prj/out/target/product/fpga/vendor.img
```

## 3.make qemu image

### 3.1. generate android ramdisk cpio

```shell
$cd nuclei-linux-sdk/work/evalsoc/linux
$../../../linux/usr/gen_initramfs.sh -o ramdisk.cpio aosp_prj/out/target/product/fpga/ramdisk
$lz4 ramdisk.cpio ramdisk.cpio.lz4 -f -9 -l
$export PATH=nuclei-linux-sdk/work/evalsoc/u-boot/tools:$PATH
$mkimage -A riscv -T ramdisk -C lz4 -n Initrd -d ramdisk.cpio.lz4 uInitrd.lz4
```
here uInitrd.lz4 is different from linux sdk output uInitrd.lz4.


### 3.2. generate image for qemu

```shell
$dd if=/dev/zero of=qemu_sd.img bs=4M count=1024
/*setup loop device*/
$sudo losetup -fP qemu_sd.img
/*get loop device number*/
$losetup -l
/*suppose qemu_sd.img use loop device /dev/loop13 */
$sudo fdisk /dev/loop13
```

use fdisk to create 4 partition:
p1: 128M for boot partition,
p2: 1G for system partition, 
p3: 128M for vendor partition, 
p4: remain space for data partition

```shell
$sudo mkfs.fat /dev/loop13p1
$mkdir mnt_dir
$sudo mount /dev/loop13p1 mnt_dir
$sudo cp nuclei_linux_sdk/work/evalsoc/boot/boot.scr mnt_dir
$sudo cp nuclei_linux_sdk/work/evalsoc/boot/uImage.lz4 mnt_dir
/* copy Android ramdisk to p1 partition*/
$sudo cp uInitrd.lz4 mnt_dir
$sudo umount mnt_dir

$cd aosp_prj/out/target/product/fpga/
$sudo dd if=system.img of=/dev/loop13p2 bs=1M
$sudo dd if=vendor.img of=/dev/loop13p3 bs=1M
$sudo mkfs.ext4 -L userdata /dev/loop13p4
$sudo losetup -d /dev/loop13
```

fdisk p command show partition result:

```
/dev/loop13p1         2048   264191   262144  128M  c W95 FAT32 (LBA)
/dev/loop13p2       264192  2361343  2097152    1G 83 Linux
/dev/loop13p3      2361344  2623487   262144  128M 83 Linux
/dev/loop13p4      2623488 16777215 14153728  6.8G 83 Linux
```

## 4.run android image on qemu

- 1.install nuclei qemu for linux
  
  please refer to nuclei-linux-sdk/README.md about `Install Nuclei Tools`

- 2.run qemu

```shell
$cd nuclei_linux_sdk/
$qemu-system-riscv64 -M nuclei_evalsoc,download=flashxip -smp 4 -m 2G -cpu nuclei-ux900fd,ext=v_zba_zbb_zbs,sv39=on,sv48=off,sv57=off  -bios work/evalsoc/freeloader/freeloader.elf -nographic -drive file=qemu_sd.img,if=sd,format=raw
```

- 3.qemu log

There are several key information points in the qemu log:
1. bootanim service startup, indicating the start of boot animation
2. bootanim exits, indicating that the system interface has started to enter
3. The top command shows the com.system.ui process, indicating that the system has been launched to the main interface

The first startup to enter the system UI will takes about 9 hours.

```
guibing@whml1:/Local/home/guibing/nuclei-linux-sdk_6.1$ qemu-system-riscv64 -M nuclei_evalsoc,download=flashxip -smp 4 -m 2G -cpu nuclei-ux900fd,ext=_zba_zbb_zbs,sv39=on,sv48=off,sv57=off  -bios work/evalsoc/freeloader/freeloader.elf -nographic -drive file=test1.img,if=sd,format=raw

OpenSBI v1.3
Build time: 2023-08-21 15:44:28 +0800
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


U-Boot 2023.01-g2ffa69c0 (Aug 21 2023 - 15:44:28 +0800)

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
725 bytes read in 11 ms (63.5 KiB/s)
## Executing script at 80200000
Boot images located in .
Loading kernel: ./uImage.lz4
8638042 bytes read in 24672 ms (341.8 KiB/s)
Loading ramdisk: ./uInitrd.lz4
1792122 bytes read in 5085 ms (343.8 KiB/s)
./kernel.dtb not found, ignore it
Starts booting from SD
## Booting kernel from Legacy Image at 82000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    8637978 Bytes = 8.2 MiB
   Load Address: 80400000
   Entry Point:  80400000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at 88300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    1792058 Bytes = 1.7 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at 88000000
   Booting using the fdt blob at 0x88000000
Working FDT set to 88000000
   Uncompressing Kernel Image
   Using Device Tree in place at 0000000088000000, end 00000000880046ac
Working FDT set to 88000000

Starting kernel ...

[    0.000000] Linux version 6.6.0 (guibing@whml1.corp.nucleisys.com) (riscv-nuclei-linux-gnu-gcc (GCC) 10.2.0, GNU ld (GNU Binutils) 2.36.1) #4 SMP PREEMPT Thu Apr 11 23:21:49 CST 2024
[    0.000000] Machine model: nuclei,evalsoc
[    0.000000] SBI specification v1.0 detected
[    0.000000] SBI implementation ID=0x1 Version=0x10003
[    0.000000] SBI TIME extension detected
[    0.000000] SBI IPI extension detected
[    0.000000] SBI RFENCE extension detected
[    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
[    0.000000] printk: bootconsole [sbi0] enabled
[    0.000000] efi: UEFI not found.
[    0.000000] OF: reserved mem: 0x0000000080000000..0x000000008007ffff (512 KiB) nomap non-reusable mmode_resv0@80000000
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x0000000080000000-0x00000000fdffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000080000000-0x000000008007ffff]
[    0.000000]   node   0: [mem 0x0000000080080000-0x00000000fdffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000080000000-0x00000000fdffffff]
[    0.000000] On node 0, zone DMA32: 8192 pages in unavailable ranges
[    0.000000] SBI HSM extension detected
[    0.000000] Falling back to deprecated "riscv,isa"
[    0.000000] riscv: base ISA extensions acdfim
[    0.000000] riscv: ELF capabilities acdfim
[    0.000000] percpu: Embedded 19 pages/cpu s40040 r8192 d29592 u77824
[    0.000000] Kernel command line: earlycon=sbi console=ttyNUC0  security=selinux androidboot.selinux=permissive androidboot.hardware=fpga
[    0.000000] Dentry cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] Inode-cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 508032
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Memory: 1986624K/2064384K available (9515K kernel code, 5038K rwdata, 4096K rodata, 2179K init, 501K bss, 77760K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=8, Nodes=1
[    0.000000] rcu: Preemptible hierarchical RCU implementation.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=64 to nr_cpu_ids=8.
[    0.000000]  Trampoline variant of Tasks RCU enabled.
[    0.000000]  Tracing variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=8
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped
[    0.000000] plic: interrupt-controller@1c000000: mapped 53 interrupts with 8 handlers for 16 contexts.
[    0.000000] riscv: providing IPIs using SBI IPI extension
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000152] sched_clock: 64 bits at 33kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.008026] Console: colour dummy device 80x25
[    0.010559] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.011352] pid_max: default: 32768 minimum: 301
[    0.017852] LSM: initializing lsm=capability,selinux,integrity
[    0.018829] SELinux:  Initializing.
[    0.022644] Mount-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.023193] Mountpoint-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.072296] RCU Tasks: Setting shift to 3 and lim to 1 rcu_task_cb_adjust=1.
[    0.073791] RCU Tasks Trace: Setting shift to 3 and lim to 1 rcu_task_cb_adjust=1.
[    0.074798] riscv: ELF compat mode supported
[    0.075347] ASID allocator using 16 bits (65536 entries)
[    0.077453] rcu: Hierarchical SRCU implementation.
[    0.077789] rcu:     Max phase no-delay instances is 1000.
[    0.082885] EFI services will not be available.
[    0.086029] smp: Bringing up secondary CPUs ...
[    0.148803] cpu1: rdtime lacks granularity needed to measure unaligned access speed
[    0.230590] cpu2: rdtime lacks granularity needed to measure unaligned access speed
[    0.291992] cpu3: rdtime lacks granularity needed to measure unaligned access speed
qemu-system-riscv64: clint: invalid write: 00001010
[    1.395568] CPU4: failed to come online
qemu-system-riscv64: clint: invalid write: 00001014
[    2.460632] CPU5: failed to come online
qemu-system-riscv64: clint: invalid write: 00001018
[    3.526336] CPU6: failed to come online
qemu-system-riscv64: clint: invalid write: 0000101c
[    4.592681] CPU7: failed to come online
[    4.593933] smp: Brought up 1 node, 4 CPUs
[    4.636779] devtmpfs: initialized
[    4.657043] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    4.658233] futex hash table entries: 2048 (order: 5, 131072 bytes, linear)
[    4.663543] pinctrl core: initialized pinctrl subsystem
[    4.684631] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    4.693115] DMA: preallocated 256 KiB GFP_KERNEL pool for atomic allocations
[    4.694366] DMA: preallocated 256 KiB GFP_KERNEL|GFP_DMA32 pool for atomic allocations
[    4.695373] audit: initializing netlink subsys (disabled)
[    4.699920] audit: type=2000 audit(4.580:1): state=initialized audit_enabled=0 res=1
[    4.703338] cpuidle: using governor menu
[    4.767211] cpu0: rdtime lacks granularity needed to measure unaligned access speed
[    4.788269] HugeTLB: registered 2.00 MiB page size, pre-allocated 0 pages
[    4.789154] HugeTLB: 28 KiB vmemmap can be freed for a 2.00 MiB page
[    4.803314] iommu: Default domain type: Translated
[    4.803741] iommu: DMA domain TLB invalidation policy: strict mode
[    4.808166] SCSI subsystem initialized
[    4.812408] usbcore: registered new interface driver usbfs
[    4.813293] usbcore: registered new interface driver hub
[    4.813964] usbcore: registered new device driver usb
[    4.816741] Advanced Linux Sound Architecture Driver Initialized.
[    4.844116] vgaarb: loaded
[    4.850219] clocksource: Switched to clocksource riscv_clocksource
[    4.853271] VFS: Disk quotas dquot_6.6.0
[    4.853942] VFS: Dquot-cache hash table entries: 512 (order 0, 4096 bytes)
[    4.902435] NET: Registered PF_INET protocol family
[    4.905487] IP idents hash table entries: 32768 (order: 6, 262144 bytes, linear)
[    4.918273] tcp_listen_portaddr_hash hash table entries: 1024 (order: 2, 16384 bytes, linear)
[    4.920867] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    4.922454] TCP established hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    4.923767] TCP bind hash table entries: 16384 (order: 7, 524288 bytes, linear)
[    4.925140] TCP: Hash tables configured (established 16384 bind 16384)
[    4.927886] UDP hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    4.929046] UDP-Lite hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    4.932525] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    4.934234] PCI: CLS 0 bytes, default 64
[    4.943847] Trying to unpack rootfs image as initramfs...
[    4.946075] workingset: timestamp_bits=46 max_order=19 bucket_order=0
[    4.951019] fuse: init (API version 7.39)
[    4.953155] 9p: Installing v9fs 9p2000 file system support
[    5.066589] Freeing initrd memory: 1744K
[    5.075256] jitterentropy: Initialization failed with host not compliant with requirements: 9
[    5.076507] NET: Registered PF_ALG protocol family
[    5.077728] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 245)
[    5.080322] io scheduler mq-deadline registered
[    5.081054] io scheduler kyber registered
[    5.081939] io scheduler bfq registered
[    5.102264] 10013000.serial: ttyNUC0 at MMIO 0x10013000 (irq = 12, base_baud = 3125000) is a Nuclei UART v0
[    5.105407] printk: console [ttyNUC0] enabled
[    5.105407] printk: console [ttyNUC0] enabled
[    5.106689] printk: bootconsole [sbi0] disabled
[    5.106689] printk: bootconsole [sbi0] disabled
[    5.134460] [drm] Initialized vkms 1.0.0 20180514 for vkms on minor 0
[    5.256683] Console: switching to colour frame buffer device 128x48
[    5.293548] platform vkms: [drm] fb0: vkmsdrmfb frame buffer device
[    5.361267] brd: module loaded
[    5.389556] loop: module loaded
[    5.394927] nuclei_spi 10014000.spi: mapped; irq=13, cs=1
[    5.401031] nuclei_spi 10034000.spi: mapped; irq=14, cs=1
[    5.410644] tun: Universal TUN/TAP device driver, 1.6
[    5.412109] e1000e: Intel(R) PRO/1000 Network Driver
[    5.412322] e1000e: Copyright(c) 1999 - 2015 Intel Corporation.
[    5.413543] PPP generic driver version 2.4.2
[    5.414642] PPP BSD Compression module registered
[    5.414978] PPP Deflate Compression module registered
[    5.415405] PPP MPPE Compression module registered
[    5.415740] usbcore: registered new interface driver asix
[    5.416137] usbcore: registered new interface driver ax88179_178a
[    5.416503] usbcore: registered new interface driver cdc_ether
[    5.416900] usbcore: registered new interface driver net1080
[    5.417236] usbcore: registered new interface driver cdc_subset
[    5.417633] usbcore: registered new interface driver zaurus
[    5.418060] usbcore: registered new interface driver cdc_ncm
[    5.418426] usbcore: registered new interface driver r8153_ecm
[    5.422973] usbcore: registered new interface driver uas
[    5.423645] usbcore: registered new interface driver usb-storage
[    5.427795] mousedev: PS/2 mouse device common for all mice
[    5.428588] usbcore: registered new interface driver xpad
[    5.428863] usbcore: registered new interface driver usb_acecad
[    5.429229] usbcore: registered new interface driver aiptek
[    5.429595] usbcore: registered new interface driver hanwang
[    5.430633] usbcore: registered new interface driver kbtab
[    5.432189] device-mapper: uevent: version 1.0.3
[    5.433532] device-mapper: ioctl: 4.48.0-ioctl (2023-03-01) initialised: dm-devel@redhat.com
[    5.438232] sdhci: Secure Digital Host Controller Interface driver
[    5.438446] sdhci: Copyright(c) Pierre Ossman
[    5.473052] mmc_spi spi1.0: SD/MMC host mmc0, no DMA, no WP, no poweroff, cd polling
[    5.474548] Synopsys Designware Multimedia Card Interface Driver
[    5.475677] sdhci-pltfm: SDHCI platform and OF driver helper
[    5.477416] hid: raw HID events driver (C) Jiri Kosina
[    5.495056] usbcore: registered new interface driver usbhid
[    5.495269] usbhid: USB HID core driver
[    5.496093] ashmem: initialized
[    5.497894] riscv-pmu-sbi: SBI PMU extension is available
[    5.498931] riscv-pmu-sbi: 16 firmware and 31 hardware counters
[    5.499145] riscv-pmu-sbi: Perf sampling/filtering is not supported as sscof extension is not available
[    5.516754] u32 classifier
[    5.516876]     input device check on
[    5.517028]     Actions configured
[    5.529388] xt_time: kernel timezone is -0000
[    5.537689] Initializing XFRM netlink socket
[    5.541381] NET: Registered PF_INET6 protocol family
[    5.541473] mmc0: host does not support reading read-only switch, assuming write-enable
[    5.543487] mmc0: new SDHC card on SPI
[    5.548828] mmcblk0: mmc0:0000 QEMU! 8.00 GiB
[    5.559417] Segment Routing with IPv6
[    5.560058] In-situ OAM (IOAM) with IPv6
[    5.561767] mip6: Mobile IPv6
[    5.563140] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[    5.568939] NET: Registered PF_PACKET protocol family
[    5.570129] NET: Registered PF_KEY protocol family
[    5.571502] 9pnet: Installing 9P2000 support
[    5.575988]  mmcblk0: p1 p2 p3 p4
[    5.598876] registered taskstats version 1
[    5.630798] clk: Disabling unused clocks
[    5.631347] ALSA device list:
[    5.631561]   #0: Dummy 1
[    5.686828] Freeing unused kernel image (initmem) memory: 2176K
[    5.688446] Run /init as init process
[    5.814636] init: init first stage started!
[    5.819000] init: Unable to open /lib/modules, skipping module loading.
[    5.829254] init: Copied ramdisk prop to /second_stage_resources/system/etc/ramdisk/build.prop
[    5.839935] init: [libfs_mgr] ReadFstabFromDt(): failed to read fstab from dt
[    5.868652] init: Using Android DT directory
[    5.870208] init: Failed to read vbmeta partitions.
[    6.033599] init: DSU not detected, proceeding with normal boot
[    6.140136] init: [libfs_mgr] superblock s_max_mnt_count:65535,/dev/block/mmcblk0p2
[    7.545440] EXT4-fs (mmcblk0p2): mounted filesystem d392d8bb-6c67-58f7-b0b2-091ad46c5bc2 ro without journal. Quota mode: none.
[    7.547637] init: [libfs_mgr] __mount(source=/dev/block/mmcblk0p2,target=/system,type=ext4)=0: Success
[    7.562469] init: Switching root to '/system'
[    7.606689] vkms_vblank_simulate: vblank timer overrun
[    9.169311] EXT4-fs (mmcblk0p3): mounted filesystem 2b96c597-1e2f-5ee1-9851-c4a9fa9de36e ro without journal. Quota mode: none.
[    9.790344] printk: init: 3 output lines suppressed due to ratelimiting
[   11.573730] random: init: uninitialized urandom read (40 bytes read)
[   21.967895] random: init: uninitialized urandom read (40 bytes read)
[   21.974151] random: init: uninitialized urandom read (4 bytes read)
[   21.977050] random: init: uninitialized urandom read (4 bytes read)
[   26.097320] init: Skipping mount of system_ext, system is not dynamic.
[   26.098144] init: Skipping mount of product, system is not dynamic.
[   26.098937] init: Opening SELinux policy
[   26.398834] init: APEX Sepolicy not found
[   27.938415] init: Loading SELinux policy
[   28.003479] SELinux:  Permission bpf in class capability2 not defined in policy.
[   28.003814] SELinux:  Permission checkpoint_restore in class capability2 not defined in policy.
[   28.004119] SELinux:  Permission bpf in class cap2_userns not defined in policy.
[   28.004455] SELinux:  Permission checkpoint_restore in class cap2_userns not defined in policy.
[   28.005065] SELinux:  Class mctp_socket not defined in policy.
[   28.005340] SELinux:  Class user_namespace not defined in policy.
[   28.005645] SELinux: the above unknown classes and permissions will be denied
[   28.024780] SELinux:  policy capability network_peer_controls=1
[   28.024993] SELinux:  policy capability open_perms=1
[   28.025177] SELinux:  policy capability extended_socket_class=1
[   28.025421] SELinux:  policy capability always_check_network=0
[   28.025604] SELinux:  policy capability cgroup_seclabel=0
[   28.025787] SELinux:  policy capability nnp_nosuid_transition=1
[   28.026062] SELinux:  policy capability genfs_seclabel_symlinks=0
[   28.026306] SELinux:  policy capability ioctl_skip_cloexec=0
[   28.131561] audit: type=1403 audit(28.002:2): auid=4294967295 ses=4294967295 lsm=selinux res=1
[   28.338256] selinux: SELinux: Loaded file context from:
[   28.338653] selinux:                 /system/etc/selinux/plat_file_contexts
[   28.338958] selinux:                 /system_ext/etc/selinux/system_ext_file_contexts
[   28.339294] selinux:                 /product/etc/selinux/product_file_contexts
[   28.339569] selinux:                 /vendor/etc/selinux/vendor_file_contexts
[   28.585693] printk: init: 1 output lines suppressed due to ratelimiting
[   28.594726] random: init: uninitialized urandom read (40 bytes read)
[   28.743927] random: init: uninitialized urandom read (40 bytes read)
[   28.748718] random: init: uninitialized urandom read (4 bytes read)
[   28.845642] init: init second stage started!
[   29.458160] selinux: SELinux: Loaded file context from:
[   29.458526] selinux:                 /system/etc/selinux/plat_file_contexts
[   29.458862] selinux:                 /system_ext/etc/selinux/system_ext_file_contexts
[   29.459228] selinux:                 /product/etc/selinux/product_file_contexts
[   29.459564] selinux:                 /vendor/etc/selinux/vendor_file_contexts
[   29.710601] init: Using Android DT directory /proc/device-tree/firmware/android/
[   29.728851] init: Couldn't load property file '/second_stage_resources/system/etc/ramdisk/build.prop': Skipping insecure file
[   29.798248] init: Overriding previous property 'dalvik.vm.usejit':'true' with new value 'false'
[   29.803985] audit: type=1107 audit(29.674:3): pid=1 uid=0 auid=4294967295 ses=4294967295 subj=u:r:init:s0 msg='avc:  denied  { set } for property=gralloc.drm.kms pid=1 uid=0 gid=0 scontext=u:r:vendor_init:s0 tcontext=u:object_r:default_prop:s0 tclass=property_service permissive=1'
[   29.901275] init: Overriding previous property 'tombstoned.max_tombstone_count':'50' with new value '10'
[   30.136535] random: init: uninitialized urandom read (40 bytes read)
[   30.387512] random: init: uninitialized urandom read (40 bytes read)
[   30.403900] random: init: uninitialized urandom read (4 bytes read)
[   32.348022] ueventd: ueventd started!
[   32.411529] selinux: SELinux: Loaded file context from:
[   32.411987] selinux:                 /system/etc/selinux/plat_file_contexts
[   32.412689] selinux:                 /system_ext/etc/selinux/system_ext_file_contexts
[   32.413299] selinux:                 /product/etc/selinux/product_file_contexts
[   32.413909] selinux:                 /vendor/etc/selinux/vendor_file_contexts
[   32.422943] ueventd: Parsing file /system/etc/ueventd.rc...
[   32.435241] ueventd: Added '/vendor/etc/ueventd.rc' to import list
[   32.436157] ueventd: Added '/odm/etc/ueventd.rc' to import list
[   32.445159] ueventd: Parsing file /vendor/etc/ueventd.rc...
[   48.275787] apexd: Bootstrap subcommand detected
[   48.571258] cutils-trace: Error opening trace file: No such file or directory (2)
[   48.577697] apexd-bootstrap: Scanning /system/apex for pre-installed ApexFiles
[   48.626983] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.permission.apex
[   49.402496] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.wifi.apex
[   50.168487] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.tzdata.apex
[   50.878356] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.runtime.apex
[   51.616394] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.i18n.apex
[   52.344116] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.tethering.apex
[   53.082885] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.neuralnetworks.apex
[   53.844299] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.adbd.apex
[   54.589019] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.appsearch.apex
[   55.340179] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.threadnetwork.apex
[   56.101165] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.ipsec.apex
[   56.861907] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.extservices.apex
[   57.649993] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.vndk.current.apex
[   58.402252] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.conscrypt.apex
[   59.144836] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.media.apex
[   59.864105] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.resolv.apex
[   60.573669] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.btservices.apex
[   61.295227] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.scheduling.apex
[   62.040740] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.os.statsd.apex
[   62.747161] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.media.swcodec.apex
[   63.459289] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.adservices.apex
[   64.162963] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.virt.apex
[   64.875976] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.mediaprovider.apex
[   65.596893] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.ondevicepersonalization.apex
[   66.330505] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.rkpd.apex
[   67.095703] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.art.debug.apex
[   67.816955] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.sdkext.apex
[   68.557159] apexd-bootstrap: Found pre-installed APEX /system/apex/com.android.uwb.apex
[   69.335205] apexd-bootstrap: Scanning /system_ext/apex for pre-installed ApexFiles
[   69.336334] apexd-bootstrap: /system_ext/apex does not exist. Skipping
[   69.336975] apexd-bootstrap: Scanning /product/apex for pre-installed ApexFiles
[   69.337768] apexd-bootstrap: /product/apex does not exist. Skipping
[   69.338348] apexd-bootstrap: Scanning /vendor/apex for pre-installed ApexFiles
[   69.339111] apexd-bootstrap: /vendor/apex does not exist. Skipping
[   69.341430] apexd-bootstrap: Found bootstrap APEX /system/apex/com.android.tzdata.apex
[   69.342346] apexd-bootstrap: Found bootstrap APEX /system/apex/com.android.vndk.current.apex
[   69.343078] apexd-bootstrap: Found bootstrap APEX /system/apex/com.android.i18n.apex
[   69.343780] apexd-bootstrap: Found bootstrap APEX /system/apex/com.android.runtime.apex
[   69.355010] audit: type=1400 audit(69.222:4): avc:  denied  { create } for  pid=59 comm="kdevtmpfs" name="loop8" scontext=u:r:kernel:s0 tcontext=u:object_r:device:s0 tclass=blk_file permissive=1
[   69.356597] audit: type=1400 audit(69.222:5): avc:  denied  { setattr } for  pid=59 comm="kdevtmpfs" name="loop8" dev="devtmpfs" ino=138 scontext=u:r:kernel:s0 tcontext=u:object_r:device:s0 tclass=blk_file permissive=1
[   69.641784] loop0: detected capacity change from 0 to 1616
[   69.920318] EXT4-fs (loop0): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[   70.487365] loop1: detected capacity change from 0 to 37256
[   70.662170] EXT4-fs (loop1): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[   70.770812] loop2: detected capacity change from 0 to 70200
[   70.920959] EXT4-fs (loop2): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[   70.956268] loop3: detected capacity change from 0 to 21792
[   71.128448] EXT4-fs (loop3): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[   71.309234] printk: apexd: 14 output lines suppressed due to ratelimiting
[   71.325927] init: Service 'apexd-bootstrap' (pid 95) exited with status 0 waiting took 39.337002 seconds
[   71.327056] init: Sending signal 9 to service 'apexd-bootstrap' (pid 95) process group...
[   71.334228] libprocessgroup: Successfully killed process cgroup uid 0 pid 95 in 4ms
[   76.874694] init: linkerconfig generated /linkerconfig with mounted APEX modules info
[   76.875854] init: Command 'update_linker_config' action=early-init (/system/etc/init/hw/init.rc:79) took 5530ms and succeeded
[   76.900939] init: processing action (early-init) from (/init.environ.rc:2)
[   76.907135] init: processing action (early-init) from (/system/etc/init/prng_seeder.rc:5)
[   76.910461] init: starting service 'prng_seeder'...
[   76.914855] init: Created socket '/dev/socket/prng_seeder', mode 666, user 1092, group 1092
[   77.048492] init: ... started service 'prng_seeder' has pid 141
[   77.051361] init: Command 'start prng_seeder' action=early-init (/system/etc/init/prng_seeder.rc:6) took 142ms and succeeded
[   77.054382] init: processing action (ro.product.cpu.abilist64=* && early-init) from (/vendor/etc/init/boringssl_self_test.rc:4)
[   77.536285] init: starting service 'boringssl_self_test64_vendor'...
[   83.907897] init: Service 'boringssl_self_test64_vendor' (pid 142) exited with status 0 waiting took 6.352000 seconds
[   83.909820] init: Sending signal 9 to service 'boringssl_self_test64_vendor' (pid 142) process group...
[   83.912658] libprocessgroup: Successfully killed process cgroup uid 0 pid 142 in 1ms
[   83.925567] init: processing action (wait_for_coldboot_done) from (<Builtin Action>:0)
[   83.926849] init: start_waiting_for_property("ro.cold_boot_done", "true"): already set
[   83.928802] init: processing action (SetMmapRndBits) from (<Builtin Action>:0)
[   83.932708] init: processing action (KeychordInit) from (<Builtin Action>:0)
[   83.934661] init: processing action (init) from (/system/etc/init/hw/init.rc:97)
[   83.946685] init: Command 'copy /system/etc/prop.default /dev/urandom' action=init (/system/etc/init/hw/init.rc:102) took 0ms and failed: Could not read input file '/system/etc/prop.default': open() failed: No such file or directory
[   84.128570] init: Command 'write /dev/cpuctl/nnapi-hal/cpu.uclamp.min 1' action=init (/system/etc/init/hw/init.rc:195) took 2ms and failed: Unable to write to file '/dev/cpuctl/nnapi-hal/cpu.uclamp.min': open() failed: Permission denied
[   86.269073] servicemanager: Starting sm instance on /dev/binder
[   87.326477] SELinux: SELinux: Loaded service context from:
[   87.328460] SELinux:                 /system/etc/selinux/plat_service_contexts
[   87.333221] SELinux:                 /system_ext/etc/selinux/system_ext_service_contexts
[   87.334167] SELinux:                 /product/etc/selinux/product_service_contexts
[   87.335083] SELinux:                 /vendor/etc/selinux/vendor_service_contexts
[   91.070281] init: Command 'symlink /sdcard /storage/sdcard0' action=init (/vendor/etc/init/hw/init.fpga.rc:7) took 2460ms and failed: symlink() failed: Read-only file system
[   91.078857] init: processing action (init) from (/system/etc/init/audioserver.rc:58)
[   91.085052] init: processing action (late-init) from (/system/etc/init/hw/init.rc:512)
[   91.093200] init: processing action (late-init) from (/system/etc/init/atrace.rc:3)
[   92.825347] init: Command 'copy /system/etc/ftrace_synthetic_events.conf /sys/kernel/tracing/synthetic_events' action=late-init (/system/etc/init/atrace.rc:294) took 1466ms and failed: Could not write to output file '/sys/kernel/tracing/synthetic_events': open() failed: No such file or directory
[   92.833831] init: Command 'copy /system/etc/ftrace_synthetic_events.conf /sys/kernel/debug/tracing/synthetic_events' action=late-init (/system/etc/init/atrace.rc:295) took 4ms and failed: Could not write to output file '/sys/kernel/debug/tracing/synthetic_events': open() failed: No such file or directory
[   92.843872] init: processing action (queue_property_triggers) from (<Builtin Action>:0)
[   92.846008] init: processing action (early-fs) from (/system/etc/init/hw/init.rc:545)
[   92.849273] init: starting service 'vold'...
console:/ $ [   92.994689] init: ... started service 'vold' has pid 156
[   93.612579] prng_seeder: Hanging forever because setup failed: hwrng.read_exact in new
[   93.612579]
[   93.613494] Caused by:
[   93.613830]     No such device (os error 19)
[   94.190673] EXT4-fs: Ignoring removed nomblk_io_submit option
[   95.106597] logd.auditd: start
[   95.107299] logd.klogd: 94987507324
[   97.535522] logd: Loaded bug_map file: /system_ext/etc/selinux/bug_map
[   97.537384] logd: Loaded bug_map file: /vendor/etc/selinux/selinux_denial_metadata
[   98.610931] logd: Loaded bug_map file: /system/etc/selinux/bug_map
[   99.187164] vndservicemanager: Starting sm instance on /dev/vndbinder
[   99.709045] SELinux: SELinux: Loaded vndservice context from:
[   99.720672] SELinux:                 /vendor/etc/selinux/vndservice_contexts
[  100.709564] EXT4-fs (mmcblk0p4): recovery complete
[  100.751739] EXT4-fs (mmcblk0p4): mounted filesystem a60aa249-1ed7-4ab0-9536-11e24e90c018 r/w with ordered data mode. Quota mode: none.
[  100.754852] init: [libfs_mgr] check_fs(): mount(/dev/block/mmcblk0p4,/data,ext4)=0: Success
[  100.778289] EXT4-fs (mmcblk0p4): unmounting filesystem a60aa249-1ed7-4ab0-9536-11e24e90c018.
[  100.837646] init: [libfs_mgr] umount_retry(): unmount(/data) succeeded
[  100.842864] init: [libfs_mgr] Running /system/bin/e2fsck on /dev/block/mmcblk0p4
[  103.810058] e2fsck: e2fsck 1.46.6 (1-Feb-2023)
[  104.146331] type=1400 audit(104.006:6): avc:  denied  { read } for  comm="e2fsck" name="mmcblk0p4" dev="tmpfs" ino=340 scontext=u:r:fsck:s0 tcontext=u:object_r:block_device:s0 tclass=blk_file permissive=1
[  104.154144] type=1400 audit(104.006:7): avc:  denied  { open } for  comm="e2fsck" path="/dev/block/mmcblk0p4" dev="tmpfs" ino=340 scontext=u:r:fsck:s0 tcontext=u:object_r:block_device:s0 tclass=blk_file permissive=1
[  104.156921] type=1400 audit(104.006:8): avc:  denied  { write } for  comm="e2fsck" name="mmcblk0p4" dev="tmpfs" ino=340 scontext=u:r:fsck:s0 tcontext=u:object_r:block_device:s0 tclass=blk_file permissive=1
[  104.159576] type=1400 audit(104.026:9): avc:  denied  { ioctl } for  comm="e2fsck" path="/dev/block/mmcblk0p4" dev="tmpfs" ino=340 ioctlcmd=0x127c scontext=u:r:fsck:s0 tcontext=u:object_r:block_device:s0 tclass=blk_file permissive=1
[  107.914428] e2fsck: Pass 1: Checking inodes, blocks, and sizes
[  109.304626] cutils-trace: Error opening trace file: No such file or directory (2)
[  118.256835] e2fsck: Pass 2: Checking directory structure
[  124.052856] e2fsck: Pass 3: Checking directory connectivity
[  124.127258] e2fsck: Pass 4: Checking reference counts
[  124.252838] e2fsck: Pass 5: Checking group summary information
[  124.323547] e2fsck: userdata: 1187/442368 files (6.4% non-contiguous), 56027/1769216 blocks
[  124.361236] EXT4-fs: Ignoring removed nomblk_io_submit option
[  124.739227] EXT4-fs (mmcblk0p4): mounted filesystem a60aa249-1ed7-4ab0-9536-11e24e90c018 r/w with ordered data mode. Quota mode: none.
[  124.740844] init: [libfs_mgr] __mount(source=/dev/block/mmcblk0p4,target=/data,type=ext4)=0: Success
[  124.752716] init: Userdata mounted using /vendor/etc/fstab.fpga result : 0
[  124.759155] init: Command 'mount_all /vendor/etc/fstab.fpga' action=fs (/vendor/etc/init/hw/init.fpga.rc:12) took 31760ms and succeeded
[  124.790679] init: processing action (fs) from (/system/etc/init/logd.rc:29)
[  124.795837] init: processing action (fs) from (/system/etc/init/wifi.rc:25)
[  124.801239] init: processing action (post-fs) from (/system/etc/init/hw/init.rc:549)
[  124.811218] init: starting service 'exec 1 (/system/bin/vdc checkpoint markBootAttempt)'...
[  124.916870] init: ... started service 'exec 1 (/system/bin/vdc checkpoint markBootAttempt)' has pid 172
[  124.918853] init: SVC_EXEC service 'exec 1 (/system/bin/vdc checkpoint markBootAttempt)' pid 172 (uid 1000 gid 1000+0 context default) started; waiting...
[  124.922912] init: Command 'exec - system system -- /system/bin/vdc checkpoint markBootAttempt' action=post-fs (/system/etc/init/hw/init.rc:550) took 120ms and succeeded
[  129.782165] servicemanager: getDeviceHalManifest: Reading VINTF information.
[  129.852661] servicemanager: getDeviceHalManifest: Successfully processed VINTF information
[  129.853912] servicemanager: getFrameworkHalManifest: Reading VINTF information.
[  129.897888] servicemanager: getFrameworkHalManifest: Successfully processed VINTF information
[  129.901031] servicemanager: Found android.system.suspend.ISystemSuspend/default in framework VINTF manifest.
[  130.258544] init: Command 'copy /data/system/entropy.dat /dev/urandom' action=post-fs-data (/system/etc/init/hw/init.rc:680) took 1205ms and succeeded
[  130.637451] init: Command 'mkdir /data/vendor/hardware 0771 root root' action=post-fs-data (/system/etc/init/hw/init.rc:683) took 375ms and succeeded
[  130.908386] init: Command 'mkdir /data/vendor/tombstones/wifi 0771 wifi wifi' action=post-fs-data (/system/etc/init/hw/init.rc:689) took 244ms and succeeded
[  130.916687] init: starting service 'tombstoned'...
[  130.922882] init: Created socket '/dev/socket/tombstoned_crash', mode 666, user 1000, group 1000
[  130.927490] init: Created socket '/dev/socket/tombstoned_intercept', mode 666, user 1000, group 1000
[  130.932800] init: Created socket '/dev/socket/tombstoned_java_trace', mode 666, user 1000, group 1000
[  131.058990] init: ... started service 'tombstoned' has pid 181
[  131.061981] init: Command 'start tombstoned' action=post-fs-data (/system/etc/init/hw/init.rc:690) took 146ms and succeeded
[  131.064971] init: Switched to default mount namespace
[  132.306243] incfs: IncFs_Features: failed to open features dir, assuming v1/none.: No such file or directory
[  137.383880] ServiceManagerCppClient: Service android.security.maintenance didn't start. Returning NULL
[  137.386260] vold: Unable to connect to keystore2 maintenance service for earlyBootEnded
[  137.450958] init: Service 'exec 5 (/system/bin/vdc keymaster earlyBootEnded)' (pid 182) exited with status 0 waiting took 5.557000 seconds
[  137.452545] init: Sending signal 9 to service 'exec 5 (/system/bin/vdc keymaster earlyBootEnded)' (pid 182) process group...
[  137.455749] libprocessgroup: Successfully killed process cgroup uid 1000 pid 182 in 1ms
[  137.767791] init: Wait for property 'ro.persistent_properties.ready=true' took 291ms
[  137.773101] init: service 'logd' requested start, but it is already running (flags: 4)
[  137.788970] init: starting service 'logd-reinit'...
[  137.910125] init: ... started service 'logd-reinit' has pid 183
[  137.911773] init: Command 'start logd-reinit' action=post-fs-data (/system/etc/init/hw/init.rc:722) took 135ms and succeeded
[  137.916229] init: Not setting encryption policy on: /data/apex
[  137.973907] init: Command 'mkdir /data/apex/active 0755 root system' action=post-fs-data (/system/etc/init/hw/init.rc:742) took 54ms and succeeded
[  138.234893] logd: logd reinit
[  138.567413] logd: FrameworkListener: read() failed (Connection reset by peer)
[  138.642639] cutils-trace: Error opening trace file: No such file or directory (2)
[  138.672698] apexd: Scanning /system/apex for pre-installed ApexFiles
[  138.684020] apexd: Found pre-installed APEX /system/apex/com.android.permission.apex
[  138.714447] apexd: Found pre-installed APEX /system/apex/com.android.wifi.apex
[  138.733917] apexd: Found pre-installed APEX /system/apex/com.android.tzdata.apex
[  138.742706] apexd: Found pre-installed APEX /system/apex/com.android.runtime.apex
[  138.751678] apexd: Found pre-installed APEX /system/apex/com.android.i18n.apex
[  138.760894] apexd: Found pre-installed APEX /system/apex/com.android.tethering.apex
[  138.771606] apexd: Found pre-installed APEX /system/apex/com.android.neuralnetworks.apex
[  138.780639] apexd: Found pre-installed APEX /system/apex/com.android.adbd.apex
[  139.070770] loop4: detected capacity change from 0 to 7104
[  139.817443] EXT4-fs (loop4): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  139.938934] loop5: detected capacity change from 0 to 21792
[  140.598449] EXT4-fs (loop5): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  141.423675] loop6: detected capacity change from 0 to 31616
[  143.261627] EXT4-fs (loop6): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  144.482208] loop7: detected capacity change from 0 to 10688
[  145.505096] init: Service 'exec 6 (/bin/rm -rf /data/misc/virtualizationservice)' (pid 188) exited with status 1 waiting took 3.601000 seconds
[  145.506958] init: Sending signal 9 to service 'exec 6 (/bin/rm -rf /data/misc/virtualizationservice)' (pid 188) process group...
[  145.520782] libprocessgroup: Successfully killed process cgroup uid 1081 pid 188 in 12ms
[  145.570587] init: Not setting encryption policy on: /data/preloads
[  145.863983] init: Command 'mkdir /data/local/tmp 0771 shell shell' action=post-fs-data (/system/etc/init/hw/init.rc:843) took 290ms and succeeded
[  146.106201] init: Command 'mkdir /data/fonts/files 0771 system system' action=post-fs-data (/system/etc/init/hw/init.rc:853) took 221ms and succeeded
[  146.443298] EXT4-fs (loop7): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  146.443969] init: Command 'mkdir /data/local/tests/product 0701 shell shell' action=post-fs-data (/system/etc/init/hw/init.rc:862) took 330ms and succeeded
[  146.445892] apexd: Successfully mounted package /system/apex/com.android.extservices.apex on /apex/com.android.extservices@339990000 duration=1966
[  146.778503] init: Command 'chmod 0771 /data/resource-cache' action=post-fs-data (/system/etc/init/hw/init.rc:879) took 319ms and succeeded
[  146.790832] init: Not setting encryption policy on: /data/lost+found
[  147.201477] loop8: detected capacity change from 0 to 7560
[  147.297149] init: Command 'mkdir /data/nfc/param 0770 nfc nfc' action=post-fs-data (/system/etc/init/hw/init.rc:897) took 499ms and succeeded
[  148.499267] EXT4-fs (loop8): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  148.500762] apexd: Successfully mounted package /system/apex/com.android.uwb.apex on /apex/com.android.uwb@339990000 duration=1304
[  148.546447] loop9: detected capacity change from 0 to 70200
[  148.857208] EXT4-fs (loop9): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  148.858154] apexd: Successfully mounted package /system/apex/com.android.i18n.apex on /apex/com.android.i18n@1 duration=312
[  148.870727] servicemanager: Found android.system.keystore2.IKeystoreService/default in framework VINTF manifest.
[  149.087188] loop10: detected capacity change from 0 to 37256
[  149.219024] EXT4-fs (loop10): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  149.220062] apexd: Successfully mounted package /system/apex/com.android.vndk.current.apex on /apex/com.android.vndk.vVanillaIceCream@1 duration=136
[  149.316528] loop11: detected capacity change from 0 to 1640
[  149.480346] EXT4-fs (loop11): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  149.481231] apexd: Successfully mounted package /system/apex/com.android.ipsec.apex on /apex/com.android.ipsec@339990000 duration=166
[  149.510833] loop12: detected capacity change from 0 to 1616
[  149.681152] EXT4-fs (loop12): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  149.681976] apexd: Successfully mounted package /system/apex/com.android.tzdata.apex on /apex/com.android.tzdata@339990000 duration=173
[  149.711791] loop13: detected capacity change from 0 to 7528
[  149.876098] EXT4-fs (loop13): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  149.877166] apexd: Successfully mounted package /system/apex/com.android.conscrypt.apex on /apex/com.android.conscrypt@339990000 duration=166
[  149.977905] loop14: detected capacity change from 0 to 536
[  150.153503] EXT4-fs (loop14): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  150.154418] apexd: Successfully mounted package /system/apex/com.android.scheduling.apex on /apex/com.android.scheduling@339990000 duration=178
[  150.184051] loop15: detected capacity change from 0 to 640
[  150.380371] EXT4-fs (loop15): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  150.381286] apexd: Successfully mounted package /system/apex/com.android.virt.apex on /apex/com.android.virt@2 duration=198
[  150.404632] loop16: detected capacity change from 0 to 8136
[  150.559967] EXT4-fs (loop16): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  150.560821] apexd: Successfully mounted package /system/apex/com.android.neuralnetworks.apex on /apex/com.android.neuralnetworks@339990000 duration=157
[  150.582946] loop17: detected capacity change from 0 to 8528
[  150.740264] EXT4-fs (loop17): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  150.786621] loop18: detected capacity change from 0 to 2480
[  150.970367] EXT4-fs (loop18): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  150.996185] loop19: detected capacity change from 0 to 3248
[  151.160827] EXT4-fs (loop19): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  151.195068] loop20: detected capacity change from 0 to 1320
[  151.382965] EXT4-fs (loop20): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  151.420898] loop21: detected capacity change from 0 to 6960
[  151.600402] EXT4-fs (loop21): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  151.601501] apexd: Successfully mounted package /system/apex/com.android.resolv.apex on /apex/com.android.resolv@339990000 duration=182
[  151.618286] loop22: detected capacity change from 0 to 21920
[  151.781280] EXT4-fs (loop22): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  151.782287] apexd: Successfully mounted package /system/apex/com.android.adbd.apex on /apex/com.android.adbd@339990000 duration=165
[  151.813507] loop23: detected capacity change from 0 to 31824
[  151.983215] EXT4-fs (loop23): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  151.984191] apexd: Successfully mounted package /system/apex/com.android.media.swcodec.apex on /apex/com.android.media.swcodec@339990000 duration=172
[  152.062713] loop24: detected capacity change from 0 to 17896
[  152.243103] EXT4-fs (loop24): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  152.244110] apexd: Successfully mounted package /system/apex/com.android.wifi.apex on /apex/com.android.wifi@339990000 duration=183
[  152.292297] loop25: detected capacity change from 0 to 39008
[  152.500396] EXT4-fs (loop25): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  152.501434] apexd: Successfully mounted package /system/apex/com.android.btservices.apex on /apex/com.android.btservices@339990000 duration=210
[  152.538177] loop26: detected capacity change from 0 to 4000
[  152.690338] EXT4-fs (loop26): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  152.691589] apexd: Successfully mounted package /system/apex/com.android.threadnetwork.apex on /apex/com.android.threadnetwork@339990000 duration=155
[  152.716217] loop27: detected capacity change from 0 to 536
[  152.894470] EXT4-fs (loop27): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  152.895446] apexd: Successfully mounted package /system/apex/com.android.ondevicepersonalization.apex on /apex/com.android.ondevicepersonalization@339990000 duration=181
[  152.930114] loop28: detected capacity change from 0 to 22408
[  153.114196] EXT4-fs (loop28): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  153.115203] apexd: Successfully mounted package /system/apex/com.android.tethering.apex on /apex/com.android.tethering@339990000 duration=187
[  153.168670] loop29: detected capacity change from 0 to 560
[  153.335906] EXT4-fs (loop29): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  153.338470] apexd: Successfully mounted package /system/apex/com.android.adservices.apex on /apex/com.android.adservices@339990000 duration=171
[  153.379241] loop30: detected capacity change from 0 to 19624
[  153.540527] EXT4-fs (loop30): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  153.541564] apexd: Successfully mounted package /system/apex/com.android.mediaprovider.apex on /apex/com.android.mediaprovider@339990000 duration=164
[  153.571624] loop31: detected capacity change from 0 to 149624
[  153.777526] EXT4-fs (loop31): mounted filesystem 7d1522e1-9dfa-5edb-a43e-98e3a4d20250 ro without journal. Quota mode: none.
[  154.327789] init: Wait for property 'apexd.status=activated' took 5484ms
[  154.883636] init: Parsing file /apex/com.android.adbd/etc/init.rc...
[  154.897033] init: Parsing file /apex/com.android.art/etc/init.rc...
[  154.911285] init: No user specified for service 'art_boot'. Defaults to root.
[  154.913055] init: Parsing file /apex/com.android.media.swcodec/etc/mediaswcodec.32rc...
[  154.930358] init: Parsing file /apex/com.android.media/etc/mediatranscoding.32rc...
[  154.943084] init: Parsing file /apex/com.android.os.statsd/etc/init.rc...
[  154.956298] init: Parsing file /apex/com.android.sdkext/etc/derive_classpath.rc...
[  154.968872] init: Parsing file /apex/com.android.sdkext/etc/derive_sdk.rc...
[  154.988830] init: Parsing file /apex/com.android.threadnetwork/etc/init.rc...
[  160.722930] init: linkerconfig generated /linkerconfig with mounted APEX modules info
[  160.725311] init: Command 'perform_apex_config' action=post-fs-data (/system/etc/init/hw/init.rc:997) took 6393ms and succeeded
[  160.740997] init: starting service 'derive_sdk'...
[  160.845977] init: ... started service 'derive_sdk' has pid 224
[  160.846954] init: SVC_EXEC service 'derive_sdk' pid 224 (uid 9999 gid 9999+0 context default) started; waiting...
[  160.851196] init: Command 'exec_start derive_sdk' action=post-fs-data (/system/etc/init/hw/init.rc:1002) took 120ms and succeeded
[  161.682830] init: Service 'derive_sdk' (pid 224) exited with status 0 waiting took 0.932000 seconds
[  161.683410] init: Sending signal 9 to service 'derive_sdk' (pid 224) process group...
[  161.684844] libprocessgroup: Successfully killed process cgroup uid 9999 pid 224 in 0ms
[  161.694580] init: starting service 'exec 8 (/system/bin/vdc --wait cryptfs init_user0)'...
[  162.041534] cutils-trace: Error opening trace file: No such file or directory (2)
[  167.198089] init: Service 'art_boot' (pid 231) exited with status 0 waiting took 2.195000 seconds
[  167.198699] init: Sending signal 9 to service 'art_boot' (pid 231) process group...
[  167.200561] libprocessgroup: Successfully killed process cgroup uid 0 pid 231 in 1ms
[  167.214294] init: starting service 'odsign'...
[  167.326324] init: ... started service 'odsign' has pid 232
[  167.330566] init: Command 'start odsign' action=post-fs-data (/system/etc/init/hw/init.rc:1022) took 116ms and succeeded
[  169.466949] init: Wait for property 'odsign.key.done=1' took 2131ms
[  169.476715] init: starting service 'apexd-snapshotde'...
[  169.584838] init: ... started service 'apexd-snapshotde' has pid 233
[  169.586151] init: SVC_EXEC service 'apexd-snapshotde' pid 233 (uid 0 gid 1000+0 context default) started; waiting...
[  169.992614] apexd: Snapshot DE subcommand detected
[  170.009552] cutils-trace: Error opening trace file: No such file or directory (2)
[  170.032135] apexd-snapshotde: Failed to stat /metadata/apex/sessions: No such file or directory
[  170.034423] apexd-snapshotde: Marking APEXd as ready
[  173.634063] LibBpfLoader: Section bpfloader_min_ver value is 2 [0x2]
[  173.636230] LibBpfLoader: Section bpfloader_max_ver value is 25 [0x19]
[  173.640106] LibBpfLoader: Section size_of_bpf_map_def value is 120 [0x78]
[  173.642211] LibBpfLoader: Section size_of_bpf_prog_def value is 92 [0x5c]
[  173.643432] LibBpfLoader: BpfLoader version 0x00028 ignoring ELF object /apex/com.android.tethering/etc/bpf/test.o with max ver 0x00019
[  173.646545] bpfloader: Loaded object: /apex/com.android.tethering/etc/bpf/test.o
[  173.661621] init: Service 'exec 9 (/system/bin/clean_scratch_files)' (pid 234) exited with status 0 oneshot service took 3.214000 seconds in background
[  173.663482] init: Sending signal 9 to service 'exec 9 (/system/bin/clean_scratch_files)' (pid 234) process group...
[  173.666748] libprocessgroup: Successfully killed process cgroup uid 0 pid 234 in 1ms
[  173.771484] LibBpfLoader: Section bpfloader_min_ver value is 2 [0x2]
[  178.325561] printk: bpfloader: 592 output lines suppressed due to ratelimiting
[  178.327392] init: Service 'bpfloader' (pid 236) exited with status 0 waiting took 7.172000 seconds
[  178.328399] init: Sending signal 9 to service 'bpfloader' (pid 236) process group...
[  178.330749] libprocessgroup: Successfully killed process cgroup uid 0 pid 236 in 1ms
[  178.340545] init: Untracked pid 237 received signal 9
[  178.341003] init: Untracked pid 237 did not have an associated service entry and will not be reaped
[  178.341888] init: Untracked pid 238 received signal 9
[  178.342315] init: Untracked pid 238 did not have an associated service entry and will not be reaped
[  178.802673] init: ... started service 'zygote' has pid 247
[  178.810546] init: Command 'start zygote' action=zygote-start (/system/etc/init/hw/init.rc:1061) took 190ms and succeeded
[  178.813385] init: Command 'start zygote_secondary' action=zygote-start (/system/etc/init/hw/init.rc:1062) took 0ms and failed: service zygote_secondary not found
[  178.819122] init: processing action (firmware_mounts_complete) from (/system/etc/init/hw/init.rc:508)
[  178.824890] init: processing action (early-boot) from (/system/etc/init/installd.rc:7)
[  179.094970] init: processing action (boot) from (/system/etc/init/hw/init.rc:1069)
[  179.194549] type=1400 audit(179.060:10): avc:  denied  { write } for  comm="init" name="discard_max_bytes" dev="sysfs" ino=6443 scontext=u:r:init:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  179.205383] type=1400 audit(179.070:11): avc:  denied  { open } for  comm="init" path="/sys/devices/platform/10034000.spi/spi_master/spi1/spi1.0/mmc_host/mmc0/mmc0:0000/block/mmcblk0/queue/discard_max_bytes" dev="sysfs" ino=6443 scontext=u:r:init:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  179.283203] init: starting service 'hidl_memory'...
[  179.448516] init: ... started service 'hidl_memory' has pid 248
[  179.458160] init: starting service 'vendor.audio-hal'...
[  179.602783] init: ... started service 'vendor.audio-hal' has pid 249
[  181.797607] type=1107 audit(181.662:12): uid=0 auid=4294967295 ses=4294967295 subj=u:r:init:s0 msg='avc:  denied  { set } for property=net.dns1 pid=93 uid=0 gid=0 scontext=u:r:vendor_init:s0 tcontext=u:object_r:net_dns_prop:s0 tclass=property_service permissive=1'
[  184.537322] init: starting service 'adbd'...
[  184.548614] init: Created socket '/dev/socket/adbd', mode 660, user 1000, group 1000
[  184.695312] init: ... started service 'adbd' has pid 263
[  184.698211] init: Command 'start adbd' action=boot (/vendor/etc/init/hw/init.fpga.rc:29) took 2835ms and succeeded
[  184.701446] init: processing action (boot) from (/system/etc/init/dumpstate.rc:1)
[  184.706207] init: processing action (boot) from (/system/etc/init/gsid.rc:25)
[  184.712280] init: starting service 'exec 11 (/system/bin/gsid run-startup-tasks)'...
[  184.851959] init: ... started service 'exec 11 (/system/bin/gsid run-startup-tasks)' has pid 264
[  184.856567] init: Command 'exec_background - root root -- /system/bin/gsid run-startup-tasks' action=boot (/system/etc/init/gsid.rc:26) took 148ms and succeeded
[  184.863128] init: processing action (enable_property_trigger) from (<Builtin Action>:0)
[  203.808044] init: Service 'exec 11 (/system/bin/gsid run-startup-tasks)' (pid 264) exited with status 0 oneshot service took 19.075001 seconds in background
[  203.815765] init: Sending signal 9 to service 'exec 11 (/system/bin/gsid run-startup-tasks)' (pid 264) process group...
[  203.819152] libprocessgroup: Successfully killed process cgroup uid 0 pid 264 in 1ms
[  210.941925] servicemanager: getDeviceHalManifest: Reloading VINTF information.
[  210.943542] servicemanager: getDeviceHalManifest: Reading VINTF information.
[  210.981384] servicemanager: getDeviceHalManifest: Successfully processed VINTF information
[  210.982757] servicemanager: Found android.hardware.cas.IMediaCasService/default in device VINTF manifest.
[  214.407897] type=1400 audit(214.274:13): avc:  denied  { read } for  comm="android.hardwar" name="u:object_r:default_prop:s0" dev="tmpfs" ino=103 scontext=u:r:hal_graphics_allocator_default:s0 tcontext=u:object_r:default_prop:s0 tclass=file permissive=1
[  214.427520] type=1400 audit(214.284:14): avc:  denied  { open } for  comm="android.hardwar" path="/dev/__properties__/u:object_r:default_prop:s0" dev="tmpfs" ino=103 scontext=u:r:hal_graphics_allocator_default:s0 tcontext=u:object_r:default_prop:s0 tclass=file permissive=1
[  214.446258] type=1400 audit(214.284:15): avc:  denied  { getattr } for  comm="android.hardwar" path="/dev/__properties__/u:object_r:default_prop:s0" dev="tmpfs" ino=103 scontext=u:r:hal_graphics_allocator_default:s0 tcontext=u:object_r:default_prop:s0 tclass=file permissive=1
[  214.453338] type=1400 audit(214.284:16): avc:  denied  { map } for  comm="android.hardwar" path="/dev/__properties__/u:object_r:default_prop:s0" dev="tmpfs" ino=103 scontext=u:r:hal_graphics_allocator_default:s0 tcontext=u:object_r:default_prop:s0 tclass=file permissive=1
[  221.499908] healthd: No battery devices found
[  221.599273] healthd: battery none chg=
[  243.158874] init: Service 'boringssl_self_test_apex64' (pid 265) exited with status 0 waiting took 54.973999 seconds
[  243.162475] init: Sending signal 9 to service 'boringssl_self_test_apex64' (pid 265) process group...
[  243.165893] libprocessgroup: Successfully killed process cgroup uid 9999 pid 265 in 1ms
[  243.204986] init: processing action (bootreceiver.enable=1 && ro.product.cpu.abilist64=*) from (/system/etc/init/hw/init.rc:648)
[  243.213867] selinux: SELinux: Could not get canonical path for /sys/kernel/tracing/instances/bootreceiver restorecon: No such file or directory.
[  243.228118] init: processing action (net.tcp_def_init_rwnd=*) from (/system/etc/init/hw/init.rc:1207)
[  243.233276] init: processing action (ro.debuggable=1) from (/system/etc/init/hw/init.rc:1269)
[  243.241271] init: processing action (sys.usb.config=adb && sys.usb.configfs=0) from (/system/etc/init/hw/init.usb.rc:41)
[  243.256469] init: service 'adbd' requested start, but it is already running (flags: 132)
[  243.264709] init: processing action (init.svc.audioserver=running) from (/system/etc/init/audioserver.rc:35)
[  254.180084] init: starting service 'media.swcodec'...
[  254.316833] init: ... started service 'media.swcodec' has pid 297
[  254.318634] init: service 'statsd' requested start, but it is already running (flags: 4)
[  254.330139] init: Command 'class_start main' action=nonencrypted (/system/etc/init/hw/init.rc:1180) took 8978ms and succeeded
[  254.336212] init: starting service 'gatekeeperd'...
[  254.410125] init: ... started service 'gatekeeperd' has pid 298
[  254.412658] init: service 'traced' requested start, but it is already running (flags: 132)
[  254.414886] init: service 'traced_probes' requested start, but it is already running (flags: 132)
[  254.424468] init: starting service 'usbd'...
[  254.501159] init: ... started service 'usbd' has pid 299
[  267.066833] type=1400 audit(266.895:17): avc:  denied  { read } for  comm="android.hardwar" name="u:object_r:default_prop:s0" dev="tmpfs" ino=103 scontext=u:r:hal_graphics_composer_default:s0 tcontext=u:object_r:default_prop:s0 tclass=file permissive=1
[  267.074768] type=1400 audit(266.895:18): avc:  denied  { open } for  comm="android.hardwar" path="/dev/__properties__/u:object_r:default_prop:s0" dev="tmpfs" ino=103 scontext=u:r:hal_graphics_composer_default:s0 tcontext=u:object_r:default_prop:s0 tclass=file permissive=1
[  267.077789] type=1400 audit(266.895:19): avc:  denied  { getattr } for  comm="android.hardwar" path="/dev/__properties__/u:object_r:default_prop:s0" dev="tmpfs" ino=103 scontext=u:r:hal_graphics_composer_default:s0 tcontext=u:object_r:default_prop:s0 tclass=file permissive=1
[  267.084533] type=1400 audit(266.895:20): avc:  denied  { map } for  comm="android.hardwar" path="/dev/__properties__/u:object_r:default_prop:s0" dev="tmpfs" ino=103 scontext=u:r:hal_graphics_composer_default:s0 tcontext=u:object_r:default_prop:s0 tclass=file permissive=1
[  295.754272] type=1400 audit(295.623:21): avc:  denied  { read } for  comm="storaged" name="stat" dev="sysfs" ino=6410 scontext=u:r:storaged:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  295.797943] type=1400 audit(295.663:22): avc:  denied  { open } for  comm="storaged" path="/sys/devices/platform/10034000.spi/spi_master/spi1/spi1.0/mmc_host/mmc0/mmc0:0000/block/mmcblk0/stat" dev="sysfs" ino=6410 scontext=u:r:storaged:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  295.801757] type=1400 audit(295.663:23): avc:  denied  { getattr } for  comm="storaged" path="/sys/devices/platform/10034000.spi/spi_master/spi1/spi1.0/mmc_host/mmc0/mmc0:0000/block/mmcblk0/stat" dev="sysfs" ino=6410 scontext=u:r:storaged:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  298.492980] servicemanager: Could not find android.hardware.gatekeeper.IGatekeeper/default in the VINTF manifest.
[  300.276367] servicemanager: Could not find android.hardware.net.nlinterceptor.IInterceptor/default in the VINTF manifest.
[  302.105834] servicemanager: Found android.hardware.audio.sounddose.ISoundDoseFactory/default in device VINTF manifest.
[  323.607849] init: service 'adbd' requested start, but it is already running (flags: 132)
[  323.608917] init: Control message: Processed ctl.start for 'adbd' from pid: 299 (/system/bin/usbd)
[  323.616455] init: Service 'exec 13 (/system/bin/flags_health_check BOOT_FAILURE)' (pid 300) exited with status 0 waiting took 69.079002 seconds
[  323.623413] init: Sending signal 9 to service 'exec 13 (/system/bin/flags_health_check BOOT_FAILURE)' (pid 300) process group...
[  323.626678] libprocessgroup: Successfully killed process cgroup uid 1000 pid 300 in 1ms
[  323.645019] servicemanager: Could not find android.hardware.usb.gadget.IUsbGadget/default in the VINTF manifest.
[  323.649017] init: starting service 'mdnsd'...
[  323.674987] init: Created socket '/dev/socket/mdnsd', mode 660, user 1020, group 3003
[  348.149108] cameraserver[287]: memfd_create() called without MFD_EXEC or MFD_NOEXEC_SEAL set
[  350.262298] init: ... started service 'mdnsd' has pid 330
[  350.263580] init: Control message: Processed ctl.start for 'mdnsd' from pid: 263 (/apex/com.android.adbd/bin/adbd --root_seclabel=u:r:su:s0)
[  350.266418] init: processing action (load_persist_props_action) from (/system/etc/init/logcatd.rc:29)
[  350.297180] init: Service 'usbd' (pid 299) exited with status 0 oneshot service took 95.852997 seconds in background
[  350.298553] init: Sending signal 9 to service 'usbd' (pid 299) process group...
[  350.312530] libprocessgroup: Successfully killed process cgroup uid 0 pid 299 in 12ms
[  350.348022] init: Service 'exec 12 (/system/bin/bootstat --set_system_boot_reason)' (pid 282) exited with status 0 oneshot service took 107.036003 seconds in background
[  350.361145] init: Sending signal 9 to service 'exec 12 (/system/bin/bootstat --set_system_boot_reason)' (pid 282) process group...
[  350.364562] libprocessgroup: Successfully killed process cgroup uid 1000 pid 282 in 1ms
[  350.401123] init: processing action (llk.enable=0) from (/system/etc/init/llkd.rc:12)
[  355.818298] type=1400 audit(355.682:24): avc:  denied  { read } for  comm="storaged" name="stat" dev="sysfs" ino=6410 scontext=u:r:storaged:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  355.824859] type=1400 audit(355.692:25): avc:  denied  { open } for  comm="storaged" path="/sys/devices/platform/10034000.spi/spi_master/spi1/spi1.0/mmc_host/mmc0/mmc0:0000/block/mmcblk0/stat" dev="sysfs" ino=6410 scontext=u:r:storaged:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  355.827880] type=1400 audit(355.692:26): avc:  denied  { getattr } for  comm="storaged" path="/sys/devices/platform/10034000.spi/spi_master/spi1/spi1.0/mmc_host/mmc0/mmc0:0000/block/mmcblk0/stat" dev="sysfs" ino=6410 scontext=u:r:storaged:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  388.373870] type=1400 audit(388.244:27): avc:  denied  { read } for  comm="surfaceflinger" name="uevent" dev="sysfs" ino=2577 scontext=u:r:surfaceflinger:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  388.378662] type=1400 audit(388.244:28): avc:  denied  { open } for  comm="surfaceflinger" path="/sys/devices/platform/vkms/uevent" dev="sysfs" ino=2577 scontext=u:r:surfaceflinger:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  388.383941] type=1400 audit(388.244:29): avc:  denied  { getattr } for  comm="surfaceflinger" path="/sys/devices/platform/vkms/uevent" dev="sysfs" ino=2577 scontext=u:r:surfaceflinger:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  388.635528] servicemanager: Found android.system.net.netd.INetd/default in framework VINTF manifest.
[  437.415222] servicemanager: Could not find android.hardware.graphics.composer3.IComposer/default in the VINTF manifest.
[  439.479034] servicemanager: Could not find android.hardware.graphics.allocator.IAllocator/default in the VINTF manifest.
[  439.855926] init: starting service 'bootanim'...
[  439.983184] init: ... started service 'bootanim' has pid 476
[  439.986816] init: Control message: Processed ctl.start for 'bootanim' from pid: 262 (/system/bin/surfaceflinger)
[  452.704803] type=1400 audit(452.566:30): avc:  denied  { read } for  comm="BootAnimation" name="uevent" dev="sysfs" ino=2577 scontext=u:r:bootanim:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  452.707397] type=1400 audit(452.566:31): avc:  denied  { open } for  comm="BootAnimation" path="/sys/devices/platform/vkms/uevent" dev="sysfs" ino=2577 scontext=u:r:bootanim:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  452.715667] type=1400 audit(452.566:32): avc:  denied  { getattr } for  comm="BootAnimation" path="/sys/devices/platform/vkms/uevent" dev="sysfs" ino=2577 scontext=u:r:bootanim:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  454.789947] hrtimer: interrupt took 9918213 ns
[  454.812225] servicemanager: Could not find android.hardware.graphics.allocator.IAllocator/default in the VINTF manifest.

console:/ $ top
Tasks: 214 total,   4 running, 210 sleeping,   0 stopped,   0 zombie
  Mem:  1990544K total,   520560K used,  1469984K free,     3104K buffers
 Swap:        0K total,        0K used,        0K free,   184076K cached
800%cpu 102%user   0%nice 139%sys 513%idle  46%iow   0%irq   0%sirq   0%host
  PID USER         PR  NI VIRT  RES  SHR S[%CPU] %MEM     TIME+ ARGS
   23 root          0 -20    0    0    0 R 96.8   0.0   0:17.90 [kworker/1:0H+k+
  262 system       12  -8 8.8G 111M  23M S 76.0   5.6   1:38.94 surfaceflinger
  601 shell        20   0 8.3G 4.3M 3.5M R 55.2   0.2   0:01.47 top
  145 system       20   0 8.3G 4.4M 3.4M R 12.8   0.2   0:27.23 servicemanager
  287 cameraserver 20   0 8.7G  23M  19M R 10.4   1.1   0:22.29 cameraserver
  476 graphics     16  -4 9.0G 102M  33M S  7.2   5.2   0:37.75 bootanimation
  259 audioserver  20   0 8.7G  21M  17M S  5.6   1.1   0:20.24 audioserver
   16 root         20   0    0    0    0 I  1.6   0.0   0:02.52 [rcu_preempt]
  253 system       -3  -8 8.4G 7.5M 6.2M S  0.8   0.3   0:01.74 android.hardwar+
  154 root         20   0    0    0    0 I  0.8   0.0   0:00.80 [kworker/2:3-ev+
    1 root         20   0 8.4G  10M 6.9M S  0.8   0.5   0:39.79 init second_sta+
  520 root          0 -20 8.4G  29M  23M D  0.0   1.4   0:28.41 dex2oatd64 --ru+
  509 root          0 -20    0    0    0 I  0.0   0.0   0:00.00 [kworker/1:2H-m+
  393 root         20   0 8.2G 2.9M 2.2M S  0.0   0.1   0:00.72 iptables-restor+
  376 root         20   0 8.2G 3.1M 2.2M S  0.0   0.1   0:00.72 ip6tables-resto+
  330 mdnsr        20   0 8.3G 2.9M 2.3M S  0.0   0.1   0:00.79 mdnsd
  298 system       20   0 8.3G 5.2M 4.4M S  0.0   0.2   0:00.72 gatekeeperd /da+
  297 mediacodec   20   0 8.5G  12M  10M S  0.0   0.6   0:03.22 media.swcodec o+
  296 wifi         20   0 8.3G 5.8M 4.8M S  0.0   0.3   0:00.96 wificond
  295 root         30  10 8.3G 4.9M 4.2M S  0.0   0.2   0:00.91 storaged
Tasks: 214 total,   4 running, 210 sleeping,   0 stopped,   0 zombie
  Mem:  1990544K total,   520560K used,  1469984K free,     3104K buffers
 Swap:        0K total,        0K used,        0K free,   184200K cached
800%cpu 102%user   0%nice 139%sys 513%idle  46%iow   0%irq   0%sirq   0%host
  PID USER         PR  NI VIRT  RES  SHR S[%CPU] %MEM     TIME+ ARGS
   23 root          0 -20    0    0    0 R 96.8   0.0   0:17.90 [kworker/1:0H+kblockd]
  262 system       12  -8 8.8G 111M  23M S 76.0   5.6   1:38.94 surfaceflinger
  601 shell        20   0 8.3G 4.3M 3.5M R 55.2   0.2   0:01.47 top
  145 system       20   0 8.3G 4.4M 3.4M R 12.8   0.2   0:27.23 servicemanager
  287 cameraserver 20   0 8.7G  23M  19M R 10.4   1.1   0:22.29 cameraserver
  476 graphics     16  -4 9.0G 102M  33M S  7.2   5.2   0:37.75 bootanimation
  259 audioserver  20   0 8.7G  21M  17M S  5.6   1.1   0:20.24 audioserver
   16 root         20   0    0    0    0 I  1.6   0.0   0:02.52 [rcu_preempt]
  253 system       -3  -8 8.4G 7.5M 6.2M S  0.8   0.3   0:01.74 android.hardware.graphics.composer@2.1-service+
  154 root         20   0    0    0    0 I  0.8   0.0   0:00.80 [kworker/2:3-events]
    1 root         20   0 8.4G  10M 6.9M S  0.8   0.5   0:39.79 init second_stage
  520 root          0 -20 8.4G  29M  23M D  0.0   1.4   0:28.41 dex2oatd64 --runtime-arg -Xbootclasspath:/apex+
  509 root          0 -20    0    0    0 I  0.0   0.0   0:00.00 [kworker/1:2H-mmc_complete]
  393 root         20   0 8.2G 2.9M 2.2M S  0.0   0.1   0:00.72 iptables-restore --noflush -w -v
  376 root         20   0 8.2G 3.1M 2.2M S  0.0   0.1   0:00.72 ip6tables-restore --noflush -w -v
  330 mdnsr        20   0 8.3G 2.9M 2.3M S  0.0   0.1   0:00.79 mdnsd
  298 system       20   0 8.3G 5.2M 4.4M S  0.0   0.2   0:00.72 gatekeeperd /data/misc/gatekeeper
  297 mediacodec   20   0 8.5G  12M  10M S  0.0   0.6   0:03.22 media.swcodec oid.media.swcodec/bin/mediaswcod+
  296 wifi         20   0 8.3G 5.8M 4.8M S  0.0   0.3   0:00.96 wificond
  295 root         30  10 8.3G 4.9M 4.2M S  0.0   0.2   0:00.91 storaged
  294 root         20   0 8.5G  15M  13M S  0.0   0.7   0:04.81 mediatuner
  293 media        20   0 8.5G  23M  19M S  0.0   1.1   0:05.51 mediaserver64
  292 media        20   0 8.3G 6.8M 5.5M S  0.0   0.3   0:01.53 media.metrics diametrics
  291 mediaex      20   0 8.6G  23M  19M S  0.0   1.1   0:05.83 media.extractor aextractor
  290 root         20   0 8.4G 4.9M 4.2M S  0.0   0.2   0:00.66 installd
console:/ $ [  595.881561] type=1400 audit(595.746:33): avc:  denied  { read } for  comm="storaged" name="stat" dev="sysfs" ino=6410 scontext=u:r:storaged:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  595.887176] type=1400 audit(595.756:34): avc:  denied  { open } for  comm="storaged" path="/sys/devices/platform/10034000.spi/spi_master/spi1/spi1.0/mmc_host/mmc0/mmc0:0000/block/mmcblk0/stat" dev="sysfs" ino=6410 scontext=u:r:storaged:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
[  595.895416] type=1400 audit(595.766:35): avc:  denied  { getattr } for  comm="storaged" path="/sys/devices/platform/10034000.spi/spi_master/spi1/spi1.0/mmc_host/mmc0/mmc0:0000/block/mmcblk0/stat" dev="sysfs" ino=6410 scontext=u:r:storaged:s0 tcontext=u:object_r:sysfs:s0 tclass=file permissive=1
  ....

```


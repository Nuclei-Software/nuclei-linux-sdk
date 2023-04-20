# OPTEE 说明

本文档是说明RISC-V架构相关的OPTEE实现，不讲OPTEE的工作原理，OPTEE的工作原理请参考官方文档(http://optee.readthedocs.io/).

我们基于RISC-V实现的OPTEE和ARM基本类似，也分为两个世界：安全世界(TEE)，非安全世界(REE)。两个世界彼此隔离，包括代码执行隔离，中断隔离。目前单核开发测试完成，多核还在开发中。实现TEE系统目前仅需要M模式下PLIC中断控制器pending可写。

## 启动过程

optee-os 会被freeloader从flash介质加载到内存，由opensbi来初始化optee，初始化完成后opensbi继续启动uboot，直到linux启动完成。

## 运行过程

RISC-V OPTEE系统的运行架构如下图：

![](optee_riscv_arch.png)

通过PMP将TEE与REE的运行地址空间隔离开，通过PLIC中断使能模式的切换实现中断隔离，即安全中断在安全世界处理，非安全中断在非安全世界处理，碰到不属于本世界处理的中断，需要经过M模式转发到另一个世界处理。

## 中断安全设置

我们使用了一个表来记录哪些中断是安全中断，M模式在切换世界时，会根据进入的时间来决定安全中断应该设置为什么模式响应，同时将M模式中断代理打开。例如在进入REE世界前，M模式软件会设置安全中断为M模式响应，非安全中断设置为S模式响应，在进入TEE世界前，M模式软件会设置安全中断为S模式响应，非安全中断设置为M模式响应。安全中断表的配置在opensbi 仓库中plic_init_sec_interrupt_tab 函数中完成，

- plic_secure_int[0]记录多少个安全中断
- plic_secure_int[x]记录第x个安全中断的硬件中断号

```
void plic_init_sec_interrupt_tab(void)
{
	/*have security interrupt currently*/
	plic_secure_int[0] = 2;

	/*support secure interrupt : timer int*/
	/*use 38,39 as secure interrupt for debug only*/
	plic_secure_int[1] = 38;
	plic_secure_int[2] = 39;

	/**debug only*/
	/*set 38,39 priority,threshold*/
	*(unsigned int *)0x1c000098 = 1;
	*(unsigned int *)0x1c00009c = 1;
	*(unsigned int *)0x1c200000 = 0;

	csr_set(CSR_MIE, MIP_MEIP);
}
```

如需要动态改变中断安全属性的，需要S模式发请求由M模式完成，M模式可以预置一张表，标识哪些中断能动态改变安全属性，哪些一直是安全属性，具体这个过程我们暂时未实现。

## 编译部署

optee 仓库包括optee-os，optee-client，optee-test，optee-example编译和部署已集成到顶层Makefile中，编译SDK时会默认编译optee各部分，典型的编译如下：
```makefile
make SOC=evalsoc CORE=ux900fd BOOT_MODE=sd freeloader
make SOC=evalsoc CORE=ux900fd BOOT_MODE=sd bootimages
```
optee-client编译后的tee-supplicant, libteec会安装到rootfs。

optee-test 编译产生的ta，ca，plugin 会安装到rootfs。

具体编译过程及安装可以参考Makefile 文件

linux系统需要配置TEE driver，dts需要配置optee节点，以便启动时加载OPTEE驱动。

## 启动运行日志

下面的打印包括系统的启动过程及运行的应用程序，运行了三个CA(client application)应用程序：optee_example_hello_world，xtest 1006测试，optee_example_demo，optee_example_demo展示的是中断的转发处理过程。

登录用户名：root

登录密码：nuclei

```
OpenSBI v0.9
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name             : Nuclei Evaluation SoC
Platform Features         : timer,mfdeleg
Platform HART Count       : 8
Firmware Base             : 0xa0000000
Firmware Size             : 184 KB
Runtime SBI Version       : 0.2

Domain0 Name              : root
Domain0 Boot HART         : 0
Domain0 HARTs             : 0*,1*,2*,3*,4*,5*,6*,7*
Domain0 Region00          : 0x00000000a0000000-0x00000000a003ffff ()
Domain0 Region01          : 0x0000000000000000-0xffffffffffffffff (R,W,X)
Domain0 Next Address      : 0x00000000a1000000
Domain0 Next Arg1         : 0x00000000a8000000
Domain0 Next Mode         : S-mode
Domain0 SysReset          : yes

[SM] Initializing ... hart [0]
I/TC: 
I/TC: OP-TEE version: 3.18.0-94-g3a9c1d40-dev (gcc version 10.2.0 (GCC)) #28 Thu Mar 23 08:35:31 UTC 2023 riscv
I/TC: WARNING: This OP-TEE configuration might be insecure!
I/TC: WARNING: Please check https://optee.readthedocs.io/en/latest/architecture/porting_guidelines.html
I/TC: Primary CPU initializing
I/TC: Primary CPU switching to normal world boot
[SM] security monitor has been initialized!
Boot HART ID              : 0
Boot HART Domain          : root
Boot HART ISA             : rv64imafdcsu
Boot HART Features        : scounteren,mcounteren,time
Boot HART PMP Count       : 16
Boot HART PMP Granularity : 4096
Boot HART PMP Address Bits: 30
Boot HART MHPM Count      : 0
Boot HART MHPM Count      : 0
Boot HART MIDELEG         : 0x0000000000000222
Boot HART MEDELEG         : 0x000000000000b109


U-Boot 2021.01-gc4d01f18 (Mar 23 2023 - 17:20:00 +0800)

CPU:   rv64imafdc
Model: nuclei,evalsoc
DRAM:  1.5 GiB
Board: Initialized
MMC:   Nuclei SPI version 0xee010102
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
408 bytes read in 548 ms (0 Bytes/s)
## Executing script at a1000000
Loading kernel
4014349 bytes read in 32137 ms (121.1 KiB/s)
Loading ramdisk
8217520 bytes read in 65210 ms (123 KiB/s)
kernel.dtb not found, ignore it
Starts booting from SD
## Booting kernel from Legacy Image at a2000000 ...
   Image Name:   Linux
   Image Type:   RISC-V Linux Kernel Image (lz4 compressed)
   Data Size:    4014285 Bytes = 3.8 MiB
   Load Address: a1200000
   Entry Point:  a1200000
   Verifying Checksum ... OK
## Loading init Ramdisk from Legacy Image at a9300000 ...
   Image Name:   Initrd
   Image Type:   RISC-V Linux RAMDisk Image (lz4 compressed)
   Data Size:    8217456 Bytes = 7.8 MiB
   Load Address: 00000000
   Entry Point:  00000000
   Verifying Checksum ... OK
## Flattened Device Tree blob at a8000000
   Booting using the fdt blob at 0xa8000000
   Uncompressing Kernel Image
   Using Device Tree in place at 00000000a8000000, end 00000000a80046d7

Starting kernel ...

[    0.000000] Linux version 5.10.0+ (guibing@whml1.corp.nucleisys.com) (riscv-nuclei-linux-gnu-gcc (GCC) 10.2.0, GNU ld (GNU Binutils) 2.36.1) #33 SMP Thu Mar 23 18:42:57 CST 2023
[    0.000000] OF: fdt: Ignoring memory range 0xa1000000 - 0xa1200000
[    0.000000] earlycon: sbi0 at I/O port 0x0 (options '')
[    0.000000] printk: bootconsole [sbi0] enabled
[    0.000000] efi: UEFI not found.
[    0.000000] Initial ramdisk at: 0x(____ptrval____) (8220672 bytes)
[    0.000000] Zone ranges:
[    0.000000]   DMA32    [mem 0x00000000a1200000-0x00000000fdffffff]
[    0.000000]   Normal   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x00000000a1200000-0x00000000fdffffff]
[    0.000000] Initmem setup node 0 [mem 0x00000000a1200000-0x00000000fdffffff]
[    0.000000] software IO TLB: mapped [mem 0x00000000f8b9f000-0x00000000fcb9f000] (64MB)
[    0.000000] SBI specification v0.2 detected
[    0.000000] SBI implementation ID=0x1 Version=0x9
[    0.000000] SBI v0.2 TIME extension detected
[    0.000000] SBI v0.2 IPI extension detected
[    0.000000] SBI v0.2 RFENCE extension detected
[    0.000000] SBI v0.2 HSM extension detected
[    0.000000] CPU with hartid=1 is not available
[    0.000000] CPU with hartid=2 is not available
[    0.000000] CPU with hartid=3 is not available
[    0.000000] CPU with hartid=4 is not available
[    0.000000] CPU with hartid=5 is not available
[    0.000000] CPU with hartid=6 is not available
[    0.000000] CPU with hartid=7 is not available
[    0.000000] CPU with hartid=1 is not available
[    0.000000] CPU with hartid=2 is not available
[    0.000000] CPU with hartid=3 is not available
[    0.000000] CPU with hartid=4 is not available
[    0.000000] CPU with hartid=5 is not available
[    0.000000] CPU with hartid=6 is not available
[    0.000000] CPU with hartid=7 is not available
[    0.000000] riscv: ISA extensions acdfim
[    0.000000] riscv: ELF capabilities acdfim
[    0.000000] percpu: Embedded 16 pages/cpu s25112 r8192 d32232 u65536
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 375215
[    0.000000] Kernel command line: earlycon=sbi console=ttyNUC0
[    0.000000] Dentry cache hash table entries: 262144 (order: 9, 2097152 bytes, linear)
[    0.000000] Inode-cache hash table entries: 131072 (order: 8, 1048576 bytes, linear)
[    0.000000] Sorting __ex_table...
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] Memory: 1410368K/1521664K available (4712K kernel code, 4139K rwdata, 2048K rodata, 188K init, 328K bss, 111296K reserved, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=8 to nr_cpu_ids=1.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=1
[    0.000000] NR_IRQS: 64, nr_irqs: 64, preallocated irqs: 0
[    0.000000] riscv-intc: 64 local interrupts mapped
[    0.000000] CPU with hartid=1 is not available
[    0.000000] riscv-intc: unable to find hart id for /cpus/cpu@1/interrupt-controller
[    0.000000] CPU with hartid=2 is not available
[    0.000000] riscv-intc: unable to find hart id for /cpus/cpu@2/interrupt-controller
[    0.000000] CPU with hartid=3 is not available
[    0.000000] riscv-intc: unable to find hart id for /cpus/cpu@3/interrupt-controller
[    0.000000] CPU with hartid=4 is not available
[    0.000000] riscv-intc: unable to find hart id for /cpus/cpu@4/interrupt-controller
[    0.000000] CPU with hartid=5 is not available
[    0.000000] riscv-intc: unable to find hart id for /cpus/cpu@5/interrupt-controller
[    0.000000] CPU with hartid=6 is not available
[    0.000000] riscv-intc: unable to find hart id for /cpus/cpu@6/interrupt-controller
[    0.000000] CPU with hartid=7 is not available
[    0.000000] riscv-intc: unable to find hart id for /cpus/cpu@7/interrupt-controller
[    0.000000] CPU with hartid=1 is not available
[    0.000000] plic: failed to parse hart ID for context 3.
[    0.000000] CPU with hartid=2 is not available
[    0.000000] plic: failed to parse hart ID for context 5.
[    0.000000] CPU with hartid=3 is not available
[    0.000000] plic: failed to parse hart ID for context 7.
[    0.000000] CPU with hartid=4 is not available
[    0.000000] plic: failed to parse hart ID for context 9.
[    0.000000] CPU with hartid=5 is not available
[    0.000000] plic: failed to parse hart ID for context 11.
[    0.000000] CPU with hartid=6 is not available
[    0.000000] plic: failed to parse hart ID for context 13.
[    0.000000] CPU with hartid=7 is not available
[    0.000000] plic: failed to parse hart ID for context 15.
[    0.000000] plic: interrupt-controller@1c000000: mapped 53 interrupts with 1 handlers for 16 contexts.
[    0.000000] random: get_random_bytes called from 0xffffffe00000296a with crng_init=0
[    0.000000] riscv_timer_init_dt: Registering clocksource cpuid [0] hartid [0]
[    0.000000] clocksource: riscv_clocksource: mask: 0xffffffffffffffff max_cycles: 0x1ef4687b1, max_idle_ns: 112843571739654 ns
[    0.000061] sched_clock: 64 bits at 32kHz, resolution 30517ns, wraps every 70368744171142ns
[    0.009307] Calibrating delay loop (skipped), value calculated using timer frequency.. 0.06 BogoMIPS (lpj=327)
[    0.019042] pid_max: default: 32768 minimum: 301
[    0.026184] Mount-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.033966] Mountpoint-cache hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.063140] rcu: Hierarchical SRCU implementation.
[    0.070800] EFI services will not be available.
[    0.076416] smp: Bringing up secondary CPUs ...
[    0.080657] smp: Brought up 1 node, 1 CPU
[    0.089538] devtmpfs: initialized
[    0.109924] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.119567] futex hash table entries: 256 (order: 2, 16384 bytes, linear)
[    0.127349] pinctrl core: initialized pinctrl subsystem
[    0.136138] NET: Registered protocol family 16
[    0.267242] clocksource: Switched to clocksource riscv_clocksource
[    0.288024] NET: Registered protocol family 2
[    0.301055] tcp_listen_portaddr_hash hash table entries: 1024 (order: 2, 16384 bytes, linear)
[    0.309906] TCP established hash table entries: 16384 (order: 5, 131072 bytes, linear)
[    0.321136] TCP bind hash table entries: 16384 (order: 6, 262144 bytes, linear)
[    0.334991] TCP: Hash tables configured (established 16384 bind 16384)
[    0.344543] UDP hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    0.352020] UDP-Lite hash table entries: 1024 (order: 3, 32768 bytes, linear)
[    0.361633] NET: Registered protocol family 1
[    0.373992] RPC: Registered named UNIX socket transport module.
[    0.379760] RPC: Registered udp transport module.
[    0.384155] RPC: Registered tcp transport module.
[    0.389129] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    0.398773] Trying to unpack rootfs image as initramfs...
[    4.371185] Freeing initrd memory: 8020K
[    4.380340] workingset: timestamp_bits=62 max_order=19 bucket_order=0
[    4.450195] jffs2: version 2.2. (NAND) 漏 2001-2006 Red Hat, Inc.
[    4.462310] JFS: nTxBlock = 8192, nTxLock = 65536
[    5.244598] NET: Registered protocol family 38
[    5.248992] io scheduler mq-deadline registered
[    5.253112] io scheduler kyber registered
[    5.851776] 10013000.serial: ttyNUC0 at MMIO 0x10013000 (irq = 1, base_baud = 6250000) is a Nuclei UART/USART
[    5.861633] printk: console [ttyNUC0] enabled
[    5.861633] printk: console [ttyNUC0] enabled
[    5.870147] printk: bootconsole [sbi0] disabled
[    5.870147] printk: bootconsole [sbi0] disabled
[    6.005371] brd: module loaded
[    6.097534] loop: module loaded
[    6.103851] nuclei_spi 10014000.spi: mapped; irq=2, cs=4
[    6.119903] spi-nor spi0.0: w25q256 (32768 Kbytes)
[    6.167144] random: fast init done
[    6.984771] ftl_cs: FTL header not found.
[    6.998016] nuclei_spi 10034000.spi: mapped; irq=4, cs=4
[    7.047149] mmc_spi spi1.0: SD/MMC host mmc0, no DMA, no WP, no poweroff, cd polling
[    7.056121] optee: probing for conduit method.
[    7.068542] optee: initialized driver
[    7.074523] ipip: IPv4 and MPLS over IPv4 tunneling driver
[    7.090179] NET: Registered protocol family 10
[    7.109130] Segment Routing with IPv6
[    7.112823] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[    7.124359] NET: Registered protocol family 17
[    7.145782] Freeing unused kernel memory: 188K
[    7.158843] Run /init as init process
[    7.249481] mmc0: host does not support reading read-only switch, assuming write-enable
[    7.257293] mmc0: new SDHC card on SPI
[    7.285003] mmcblk0: mmc0:0000 SD 7.39 GiB 
[    7.347381]  mmcblk0: p1
Starting syslogd: OK
Starting klogd: OK
Running sysctl: OK
Starting mdev... OK
modprobe: can't change directory to '/lib/modules': No such file or directory
Saving random seed: [   18.345916] random: dd: uninitialized urandom read (512 bytes read)
OK
Starting tee-supplicant...

Welcome to Nuclei System Technology
nucleisys login: root
Password: 
# nuclei
-bash: nuclei: command not found
# optee_example_hello_world 
M:fwd timer int to REE
D/TA:  TA_CreateEntryPoint:39 has been called
D/TA:  TA_OpenSessionEntryPoint:68 has been called
I/TA: Hello World!
Invoking TA to increment 42
D/TA:  inc_value:105 has been called
I/TA: Got value: 42 from NW
I/TA: Increase value to: 43
TA incremented value to 43
I/TA: Goodbye!
D/TA:  TA_DestroyEntryPoint:50 has been called
# xtest -t regression 1006
Test ID: 1006
Run test suite with level=0

TEE test application started over default TEE instance
######################################################
#
# regression
#
######################################################
 
* regression_1006 Test Basic OS features
M:fwd timer int to REE
ta_entry_basic: enter
Getting properties for current TA
Getting properties for current client
Getting properties for implementation
M:fwd timer int to REE
system time 6.063
REE time 75.234
E/TA:  test_time:579 TA time not stored
TA time 0.000
TA time 0.999
  regression_1006 OK
+-----------------------------------------------------
Result of testsuite regression filtered by "1006":
regression_1006 OK
+-----------------------------------------------------
2 subtests of which 0 failed
1 test case of which 0 failed
97 test cases were skipped
TEE test application done!
# optee_example_demo 
I/TA: open session!
CA:Invoking TA to increment 42 to 50
I/TA: Got value: 42 from NW
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd int38 to TEE
@M:fwd timer int to REE
I/TA: Increase value to: 43
CA:increM:fwd timer int to REE
mented value to I/TA: Got value: 43 from NW
43
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd int38 to TEE
@M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
I/TA: Increase value to: 44
CA:incremented value to 44
I/TA: Got value: 44 from NW
M:fwd timer int to REE
M:fwd int38 to TEE
@M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd int38 to TEE
@M:fwd timer int to REE
I/TA: Increase value to: 45
CA:incremented value to 45
I/TA: Got value: 45 from NW
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd int38 to TEE
@M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
I/TA: Increase value to: 46
CA:incremented value to 46
I/TA: Got value: 46 from NW
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd int38 to TEE
@M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
I/TA: Increase value to: 47
CA:incremented value to 47
I/TA: Got value: 47 from NW
M:fwd int38 to TEE
@M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd int38 to TEE
@M:fwd timer int to REE
I/TA: Increase value to: 48
CA:incremented value to 48
I/TA: Got value: 48 from NW
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd int38 to TEE
@M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
I/TA: Increase value to: 49
CA:incremented value to 49
I/TA: Got value: 49 from NW
M:fwd timer int to REE
M:fwd int38 to TEE
@M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd timer int to REE
M:fwd int38 to TEE
@I/TA: Increase value to: 50
CA:incremented value to 50
I/TA: close session!
# 
```

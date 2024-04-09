# Linux SDK SoC Configuration Generator

To enhance the convenience and efficiency of porting the Nuclei Linux SDK for our users, we've developed a Python script
designed to automate the generation of customized configuration files which located in `conf/<CUSTOMSOC>`.

With the help of the script, it will speedup the bringup of your SoC prototype using Nuclei RISC-V CPU IP, and can also evaluate
it using Nuclei QEMU.

By leveraging **conf/evalsoc** as the default reference template, this tool accept a **SoC configuration file** provided by you
to generate proper linux sdk configuration files for your customized SoC.

This script assumed your SoC used Nuclei RISC-V CPU and UART/QSPI IP, UART0, QSPI0 connected to SPIFlash, QSPI2 connected to SDCard.

> If you are not using our IP, it may need more efforts to modify opensbi, uboot and linux drivers.

> If you are using Nuclei UART/QSPI IP, the IP uboot and linux driver is still in development.

## SoC Configuration File

The configuration file is in JSON format,mainly used to config ddr, flash address,size and device irq.

A typical config file as following:

~~~json
{
    "general_config": {
        "ddr": {
            "base": "0x80000000",
            "size": "0x80000000"
        },
        "norflash": {
            "base": "0x20000000",
            "size": "32M"
        },
        "iregion": {
            "base": "0x18000000"
        },
        "uart0": {
            "base": "0x10013000",
            "irq": "33"
        },
        "uart1": {
            "base": "0x10023000",
            "irq": "34"
        },
        "qspi0": {
            "base": "0x10014000",
            "irq": "35"
        },
        "qspi2": {
            "base": "0x10034000",
            "irq": "37"
        },
        "cpu_freq": "50000000",
        "timer_freq": "32768"
    }
}
~~~

- `general_config` is mainly used to configure the board resource or chip base address

- `base` property : base address, only support hex format

- `size` property : size, support hex, dec, size string format

- `irq` property : peripheral interrupt id, dec format

The `irq`  peripheral interrupt id is equal to hardware interrupt wire connect number plus one, users should follow this rule when configuring irq.

| IRQ_HW_ID | PLIC Interrupt ID | Source |
| --------- | ----------------- | ------ |
| 32        | 33                | uart0  |
| 34        | 35                | qspi0  |
| 35        | 36                | qspi1  |
| 36        | 37                | qspi2  |

The **iregion** is Nuclei RISC-V CPU internal region, you should provide correct iregion base to match with your SoC.

If **ddr** parameter is not exist, we will use `base:0x80000000`,`size:0x80000000` as default value.

If other parameters are not exist, we will skip update them.

## How to use

Change directory to `<nuclei-linux-sdk>/conf/`, then execute the python script `genconf.py`.

~~~shell
$cd nuclei-linux-sdk/conf
$ ./genconf.py --help
usage: genconf.py [-h] [--conf CONF] [--refsoc REFSOC] custsoc

Generate configuration files based on a reference SOC.

positional arguments:
  custsoc          new config files directory.

optional arguments:
  -h, --help       show this help message and exit
  --conf CONF      json config file (default: genconf.json).
  --refsoc REFSOC  reference soc config (default: evalsoc).
~~~

generate named **rvsoc** config files with default `evalsoc` and `genconf.json`

~~~shell
$./genconf.py rvsoc
~~~

generate named **rvsoc** config files based on `xxxsoc` with `xxx.json`, support `xxxsoc` and
`xxx.json` have exist in the same directory.

~~~shell
$./genconf.py --conf xxx.json --refsoc xxxsoc rvsoc
~~~

After generate config files, you can build your linux sdk using command:

> Assume you want to use ux900fd CORE.

~~~shell
cd /path/to/nuclei-linux-sdk
# you are now in the root of Nuclei Linux SDK
# build your rvsoc and use ux900fd core
make SOC=rvsoc CORE=ux900fd freeloader bootimages
# run and evaluate it on qemu
make SOC=rvsoc CORE=ux900fd run_qemu
~~~

More detail about how to build linux sdk, please refer to Linux SDK top **README.md**.

## Example

generate rv64 rvsoc config files log as following:

~~~shell
nuclei-linux-sdk/conf$ ./genconf.py rvsoc
===Start generating rvsoc config files based on evalsoc===

>>>Updating opensbi...
Create 'rvsoc/opensbi/customsoc.c' based on 'rvsoc/opensbi/evalsoc.c'.
Replace string evalsoc with customsoc in rvsoc/opensbi/customsoc.c
Note: All custom soc should use customsoc.c for nuclei generic soc support

>>>Updating uboot config...
- rvsoc/uboot_rv32imac_sd_config:
Update with CONFIG_TEXT_BASE=0x80400000

Update with CONFIG_SYS_LOAD_ADDR=0x80400000

Update with CONFIG_CUSTOM_SYS_INIT_SP_ADDR=0x80400000

- rvsoc/uboot_rv64imac_flash_config:
Update with CONFIG_TEXT_BASE=0x80200000

Update with CONFIG_SYS_LOAD_ADDR=0x80200000

Update with CONFIG_CUSTOM_SYS_INIT_SP_ADDR=0x80200000

Update with CONFIG_BOOTCOMMAND="bootm 0x83000000 0x88300000 0x88000000"

- rvsoc/uboot_rv32imafdc_flash_config:
Update with CONFIG_TEXT_BASE=0x80400000

Update with CONFIG_SYS_LOAD_ADDR=0x80400000

Update with CONFIG_CUSTOM_SYS_INIT_SP_ADDR=0x80400000

Update with CONFIG_BOOTCOMMAND="bootm 0x83000000 0x88300000 0x88000000"

- rvsoc/uboot_rv64imac_sd_config:
Update with CONFIG_TEXT_BASE=0x80200000

Update with CONFIG_SYS_LOAD_ADDR=0x80200000

Update with CONFIG_CUSTOM_SYS_INIT_SP_ADDR=0x80200000

- rvsoc/uboot_rv32imac_flash_config:
Update with CONFIG_TEXT_BASE=0x80400000

Update with CONFIG_SYS_LOAD_ADDR=0x80400000

Update with CONFIG_CUSTOM_SYS_INIT_SP_ADDR=0x80400000

Update with CONFIG_BOOTCOMMAND="bootm 0x83000000 0x88300000 0x88000000"

- rvsoc/uboot_rv64imafdc_sd_config:
Update with CONFIG_TEXT_BASE=0x80200000

Update with CONFIG_CUSTOM_SYS_INIT_SP_ADDR=0x80200000

Update with CONFIG_SYS_LOAD_ADDR=0x80200000

- rvsoc/uboot_rv32imafdc_sd_config:
Update with CONFIG_TEXT_BASE=0x80400000

Update with CONFIG_CUSTOM_SYS_INIT_SP_ADDR=0x80400000

Update with CONFIG_SYS_LOAD_ADDR=0x80400000

- rvsoc/uboot_rv64imafdc_flash_config:
Update with CONFIG_TEXT_BASE=0x80200000

Update with CONFIG_SYS_LOAD_ADDR=0x80200000

Update with CONFIG_CUSTOM_SYS_INIT_SP_ADDR=0x80200000

Update with CONFIG_BOOTCOMMAND="bootm 0x83000000 0x88300000 0x88000000"


>>>Updating freeloader.mk...
Update DDR_BASE to 0x80000000
Update FLASH_BASE to 0x20000000
Update FLASH_SIZE to 32M
Update AMPFW_SIZE to 0x400000
Update AMP_START_CORE to 8
Update AMPFW_START_OFFSET to 0x7e000000

>>>Updating build.mk...
Update FW_TEXT_START to 0x80000000
Update UIMAGE_AE_CMD to -a 0x80400000 -e 0x80400000
Update QEMU_MACHINE_OPTS to -M nuclei_evalsoc,soc-cfg=conf/rvsoc/rvsoc.json,download=flashxip -smp 8

Updating dts...
- rvsoc/nuclei_rv32imafdc.dts:
Replace string evalsoc with rvsoc in rvsoc/nuclei_rv32imafdc.dts
Update  TIMERCLK_FREQ to 32768
Update  CPUCLK_FREQ to 50000000
Update  memory@80000000 to memory@80000000, and update reg value.
Update  interrupt-controller@1c000000 to interrupt-controller@1c000000, and update reg value.
Update  clint@18031000 to clint@18031000, and update reg value.
Update  uart0@10013000 to uart0: serial@10013000, and update reg value.
Update  uart1@10023000 to uart1: serial@10023000, and update reg value.
Update  qspi0@10014000 to qspi0: spi@10014000, and update reg value.
Update  qspi2@10034000 to qspi2: spi@10034000, and update reg value.
- rvsoc/nuclei_rv64imac.dts:
Replace string evalsoc with rvsoc in rvsoc/nuclei_rv64imac.dts
Update  TIMERCLK_FREQ to 32768
Update  CPUCLK_FREQ to 50000000
Update  memory@80000000 to memory@80000000, and update reg value.
Update  interrupt-controller@1c000000 to interrupt-controller@1c000000, and update reg value.
Update  clint@18031000 to clint@18031000, and update reg value.
Update  uart0@10013000 to uart0: serial@10013000, and update reg value.
Update  uart1@10023000 to uart1: serial@10023000, and update reg value.
Update  qspi0@10014000 to qspi0: spi@10014000, and update reg value.
Update  qspi2@10034000 to qspi2: spi@10034000, and update reg value.
- rvsoc/nuclei_rv32imac.dts:
Replace string evalsoc with rvsoc in rvsoc/nuclei_rv32imac.dts
Update  TIMERCLK_FREQ to 32768
Update  CPUCLK_FREQ to 50000000
Update  memory@80000000 to memory@80000000, and update reg value.
Update  interrupt-controller@1c000000 to interrupt-controller@1c000000, and update reg value.
Update  clint@18031000 to clint@18031000, and update reg value.
Update  uart0@10013000 to uart0: serial@10013000, and update reg value.
Update  uart1@10023000 to uart1: serial@10023000, and update reg value.
Update  qspi0@10014000 to qspi0: spi@10014000, and update reg value.
Update  qspi2@10034000 to qspi2: spi@10034000, and update reg value.
- rvsoc/nuclei_rv64imafdc.dts:
Replace string evalsoc with rvsoc in rvsoc/nuclei_rv64imafdc.dts
Update  TIMERCLK_FREQ to 32768
Update  CPUCLK_FREQ to 50000000
Update  memory@80000000 to memory@80000000, and update reg value.
Update  interrupt-controller@1c000000 to interrupt-controller@1c000000, and update reg value.
Update  clint@18031000 to clint@18031000, and update reg value.
Update  uart0@10013000 to uart0: serial@10013000, and update reg value.
Update  uart1@10023000 to uart1: serial@10023000, and update reg value.
Update  qspi0@10014000 to qspi0: spi@10014000, and update reg value.
Update  qspi2@10034000 to qspi2: spi@10034000, and update reg value.

>>>Updating uboot.cmd...
Update kernel_addr to 0x83000000, rootfs_addr to 0x88300000, fdt_addr to 0x88000000
===generate successfully!===

Here are the reference build commands for compiling Linux SDK for you:
$cd ..
$make SOC=rvsoc CORE=ux900fd BOOT_MODE=sd freeloader bootimages
$make SOC=rvsoc CORE=ux900fd BOOT_MODE=sd run_qemu
Please adjust the compilation parameters according to your real environment.
~~~

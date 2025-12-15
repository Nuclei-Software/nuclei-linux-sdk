#!/bin/env python3
import re
import json
import glob
import sys
import os
import shutil
import argparse

def is_uboot_flash_config_format(s):
    s = os.path.basename(s)
    pattern = r'^uboot_\w+_flash_config$'
    return bool(re.match(pattern, s))

def update_uboot_defconfig(config_file):
    with open(config_file, 'r') as f:
        defconfig_content = f.readlines()
    if "uboot_rv32" in config_file:
        uboot_text_base = hex(int(board_ddr_base, 16)  + 0x400000)
    else:
        uboot_text_base = hex(int(board_ddr_base, 16)  + 0x200000)
    uboot_cust_sys_init_sp_addr = uboot_text_base
    uboot_sys_load_addr = uboot_text_base

    updated_content = []
    for line in defconfig_content:
        if 'CONFIG_TEXT_BASE=' in line:
            line = f'CONFIG_TEXT_BASE={uboot_text_base}\n'
            print("Update with %s" %(line))
        if 'CONFIG_SYS_TEXT_BASE=' in line:
            line = f'CONFIG_SYS_TEXT_BASE={uboot_text_base}\n'
            print("Update with %s" %(line))
        elif 'CONFIG_CUSTOM_SYS_INIT_SP_ADDR=' in line:
            line = f'CONFIG_CUSTOM_SYS_INIT_SP_ADDR={uboot_cust_sys_init_sp_addr}\n'
            print("Update with %s" %(line))
        elif 'CONFIG_SYS_LOAD_ADDR=' in line:
            line = f'CONFIG_SYS_LOAD_ADDR={uboot_sys_load_addr}\n'
            print("Update with %s" %(line))
        elif 'CONFIG_BOOTCOMMAND=' in line: #update flashboot config bootm
            if is_uboot_flash_config_format(config_file):
                kernel_addr = hex(int(board_ddr_base, 16) + 0x3000000)
                rootfs_addr = hex(int(board_ddr_base, 16) + 0x8300000)
                fdt_addr = hex(int(board_ddr_base, 16) + 0x8000000)
                line = f'CONFIG_BOOTCOMMAND="bootm {kernel_addr} {rootfs_addr} {fdt_addr}"\n'
                print("Update with %s" %(line))
        updated_content.append(line)

    with open(config_file, 'w') as f:
        f.writelines(updated_content)

def update_uboot_cmd(file_path, kernel_load_address, rootfs_load_address, fdt_load_address):
    with open(file_path, 'r') as f:
        file_content = f.read()

    load_kernel_pattern = r'(fatload mmc 0 )0x[0-9a-fA-F]+ (\${kernelimg})'
    new_line = r'\g<1>' + kernel_load_address + r' \g<2>'
    updated_content = re.sub(load_kernel_pattern, new_line, file_content, flags=re.MULTILINE)

    load_rootfs_pattern = r'(fatload mmc 0 )0x[0-9a-fA-F]+ (\${rootfsimg})'
    new_line = r'\g<1>' + rootfs_load_address + r' \g<2>'
    updated_content = re.sub(load_rootfs_pattern, new_line, updated_content, flags=re.MULTILINE)

    load_fdt_pattern = r'(fatload mmc 0 )0x[0-9a-fA-F]+ (\${dtbimg})'
    new_line = r'\g<1>' + fdt_load_address + r' \g<2>'
    updated_content = re.sub(load_fdt_pattern, new_line, updated_content, flags=re.MULTILINE)

    bootm_pattern = r'bootm 0x[0-9a-fA-F]+ 0x[0-9a-fA-F]+ 0x[0-9a-fA-F]+'
    new_line = fr'bootm {kernel_load_address} {rootfs_load_address} {fdt_load_address}'
    updated_content = re.sub(bootm_pattern, new_line, updated_content)

    with open(file_path, 'w') as f:
        f.write(updated_content)
    print("Update kernel_addr to %s, rootfs_addr to %s, fdt_addr to %s" %(kernel_load_address, rootfs_load_address, fdt_load_address))

def update_dts_clk_freq(dts_file_path, macro_name, new_freq_value):
    if new_freq_value is None:
        print("new value is None，skip clk update %s" % macro_name)
        return

    with open(dts_file_path, 'r') as f:
        dts_content = f.read()
    # 使用.format()方法构建正则表达式和替换字符串
    pattern = r'#ifndef\s+{}\s*(\n.*)*#define\s+{}\s+(\d+)'.format(re.escape(macro_name), re.escape(macro_name))
    replacement = '#ifndef {}\n#define {}       {}'.format(macro_name, macro_name, new_freq_value)

    # 创建正则表达式并进行替换
    pattern_compiled = re.compile(pattern, flags=re.DOTALL)
    updated_text = pattern_compiled.sub(replacement, dts_content)
    with open(dts_file_path, 'w') as f:
        f.write(updated_text)
    print("Update  %s to %s" %(macro_name, new_freq_value))

def update_dts_node(dts_file_path, node_name, new_base_address, new_reg_values, new_interrupts=None):
    with open(dts_file_path, 'r') as f:
        dts_content = f.read()

    # 构造正则表达式以匹配整个节点
    pattern_node = re.compile(r'({}(?:\s*:\s*(\w+))?@(\w+))\s*{{(?:.*?reg\s*=\s*<([^>]*)>;)?(?:.*?interrupts\s*=\s*<([^>]*)>;)?.*?}}'.format(re.escape(node_name)),
        re.DOTALL
    )

    # 搜索匹配的节点
    match = pattern_node.search(dts_content)

    if match:
        # 提取旧的基地址
        old_base_address = match.group(3)

        # 构造新的节点名和准备替换reg属性值
        node_name_full = re.sub(r'@.*$', '', match.group(1))
        new_node_name = f"{node_name_full}@{new_base_address}"
        # 匹配并替换节点名（如果需要同时替换节点名的话）
        dts_content = dts_content.replace(match.group(1), new_node_name, 1)

        # 构造用于替换reg属性的新字符串，并确保只替换目标节点的reg
        reg_pattern = re.compile(rf'reg\s*=\s*<{match.group(4)}>;', re.MULTILINE)
        new_reg_content = reg_pattern.sub(f"reg = <{new_reg_values}>;", dts_content, count=1)
        # 如果提供了新的interrupts值，则更新interrupts属性
        if new_interrupts is not None:
            old_interrupts = match.group(5)
            new_reg_content = re.sub(rf'interrupts\s*=\s*<{old_interrupts}>;', f"interrupts = <{new_interrupts}>;", new_reg_content, count=1)

        # 将新的内容写回文件
        with open(dts_file_path, 'w') as f:
            f.write(new_reg_content)
        print(f"Update  {node_name}@{old_base_address} to {new_node_name}, and update reg value.")

    else:
        print("Node not found!")

def update_dts_node_simple(dts_file_path, node_name, new_reg_values):
    with open(dts_file_path, 'r') as f:
        content = f.read()

    pattern_str = r'(\b{}\s*{{[\s\S]*?)(\breg\s*=\s*<)([^>]+)([>])([\s\S]*?}})'.format(re.escape(node_name))
    pattern = re.compile(pattern_str, re.DOTALL | re.MULTILINE)

    def replacer(match):
        return f"{match.group(1)}{match.group(2)}{new_reg_values}>{match.group(5)}"

    new_content = pattern.sub(replacer, content)

    if new_content != content:
        with open(dts_file_path, 'w') as f:
            f.write(new_content)
        print(f"Updated {node_name} reg to <{new_reg_values}>")
    else:
        print(f"Node '{node_name}' not found or no change")

def update_build_variable(makefile_path, variable_name, new_value):
    with open(makefile_path, 'r') as file:
        content = file.read()

    pattern = r'^{}\s*\:=\s*(.*)'.format(variable_name)
    match = re.search(pattern, content, re.MULTILINE)
    if match:
        new_line = f"{variable_name} := {new_value}"
        content = re.sub(pattern, new_line, content, flags=re.MULTILINE)

        with open(makefile_path, 'w') as file:
            file.write(content)
        print("Update %s to %s" %(variable_name, new_value))
    else:
        print("not match %s" % variable_name)

def update_freeloader_variable(makefile_path, variable_name, new_value):
    if new_value is None:
        print("new value is None，skip update %s" % variable_name)
        return

    with open(makefile_path, 'r') as file:
        content = file.read()

    pattern = r'^{}\s*\?\=\s*(.*)'.format(variable_name)
    match = re.search(pattern, content, re.MULTILINE)
    if match:
        new_line = f"{variable_name} ?= {new_value}"
        content = re.sub(pattern, new_line, content, flags=re.MULTILINE)
        with open(makefile_path, 'w') as file:
            file.write(content)
        print("Update %s to %s" %(variable_name, new_value))
    else:
        print("not match %s" % variable_name)

def replace_in_file(file_path, old_string, new_string):
    # 读取文件内容
    with open(file_path, 'r') as file:
        file_data = file.read()
    print("Replace string %s with %s in %s" %(old_string, new_string, file_path));
    # 替换文件中的指定字符串
    file_data = file_data.replace(old_string, new_string)

    # 写回文件，覆盖原文件内容
    with open(file_path, 'w') as file:
        file.write(file_data)

def parse_size(size_str, output_format='numeric'):
    units = {'K': 1024, 'M': 1024 ** 2, 'G': 1024 ** 3, 'T': 1024 ** 4}

    match = re.match(r'^(?![0xX])(\d+)([KMGT]?)$', size_str)
    if match:
        num_part, unit_part = match.groups()
        size_num = int(num_part, 0) * units.get(unit_part, 1)
    else:
        try:
            size_num = int(size_str, 0)# 0 indicates automatic detection of decimal or hexadecimal.
        except ValueError:
            raise ValueError(f"Invalid size format: {size_str}")

    if output_format == 'numeric':
        return size_num
    elif output_format == 'string':
        for unit, multiplier in reversed(list(units.items())):
            if size_num >= multiplier:
                return f"{size_num // multiplier}{unit}"
        return str(size_num)
    else:
        raise ValueError("Invalid output_format, must be 'numeric' or 'string'")

def align_to_power_of_two(value):
    if value == 0:
        return 1
    else:
        return 1 << (value - 1).bit_length()

def find_max_interrupts(dts_content):
    interrupts_re = re.compile(r'interrupts\s*=\s*<(\d+)>;')
    max_interrupts = 0
    for match in interrupts_re.finditer(dts_content):
        interrupts_value = int(match.group(1))
        max_interrupts = max(max_interrupts, interrupts_value)
    return max_interrupts

def modify_plic_node(dts_content, aligned_value):
    plic_node_re = re.compile(rf'riscv,ndev\s*=\s*<(\d+)>;', re.DOTALL)
    modified_content = plic_node_re.sub(rf'riscv,ndev = <{aligned_value}>;', dts_content)
    return modified_content

def update_plic_intr_num(dts_file_path, irqmax=None):
    with open(dts_file_path, 'r') as f:
        dts_content = f.read()
    max_interrupts = find_max_interrupts(dts_content)
    if max_interrupts > 1024:
        print("Error: irqmax in %s file is more than 1024." %(args.conf))
        shutil.rmtree(cust_file)
        sys.exit(1)
    aligned_value = align_to_power_of_two(max_interrupts)
    if irqmax is None:
        aligned_value = min(aligned_value, 1024)
    else:
        aligned_value = min(int(irqmax), aligned_value, 1024)
    modified_content = modify_plic_node(dts_content, aligned_value)

    print("Update  plic riscv,ndev to %s" %aligned_value)
    with open(dts_file_path, 'w') as f:
        f.write(modified_content)

def update_openocd_config(file_path, **kwargs):
    with open(file_path, "r") as f:
        content = f.read()

    changes_made = False  # 标记是否有修改发生

    for key, new_value in kwargs.items():
        pattern = rf"(set\s+{key}\s+)(\S+)"
        # 先检查是否能匹配到旧值
        match = re.search(pattern, content)
        if match:
            old_value = match.group(2)
            if old_value != new_value:
                # 只有当新旧值不同时才替换
                content = re.sub(pattern, f"set {key}    {new_value}", content)
                print(f"Update {key.ljust(15)}: {old_value} to {new_value}")
                changes_made = True
            # else: 值相同则不处理
        else:
            print(f"[Warning] Config item '{key}' not found")

    if changes_made:
        with open(file_path, "w") as f:
            f.write(content)
    else:
        print("No changes were made to the config file.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Generate configuration files based on a reference SOC."
    )
    parser.add_argument("--conf", type=str, default="genconf.json", help="json config file (default: genconf.json, for rv64).If you want to generate rv32 config file, please refer to README.md.")
    parser.add_argument("--refsoc", type=str, default="evalsoc", help="reference soc config (default: evalsoc).")
    parser.add_argument("custsoc", type=str, help="new config files directory.")

    args = parser.parse_args()

    # check if custsoc arg exist
    if args.custsoc is None:
        print("Error: custsoc parameter is required but not provided.")
        parser.print_help()
        sys.exit(1)

    # check if refsoc exist
    if not os.path.exists(args.refsoc):
        print("Error: %s referenc soc not exist!\n" % args.refsoc)
        parser.print_help()
        sys.exit(1)

    # check if refsoc and custsoc in same directory
    if os.path.abspath(args.refsoc) == os.path.abspath(args.custsoc):
        print("Error: refsoc and custsoc cannot be the same directory!")
        parser.print_help()
        sys.exit(1)

    # if custsoc exist，ask if overwrite
    if os.path.exists(args.custsoc):
        print(f"{args.custsoc} already exists. Do you want to overwrite it? (y/n)")
        response = input().strip().lower()
        if response != 'y':
            print("Exiting without overwriting.")
            sys.exit(1)
        shutil.rmtree(args.custsoc)
    # copy refsoc to custsoc
    shutil.copytree(args.refsoc, args.custsoc)
    # copy json file to custsoc dir
    cust_json_file = "%s/%s.json" %(args.custsoc, args.custsoc)
    shutil.copy(args.conf, cust_json_file)
    print(f"===Start generating {args.custsoc} config files based on {args.refsoc}===")

    board_flash_base = None
    board_flash_size = None
    board_iregion_base = None
    board_uart0_base = None
    board_uart0_irq = None
    board_uart1_base = None
    board_uart1_irq = None
    board_qspi0_base = None
    board_qspi0_irq = None
    board_qspi2_base = None
    board_qspi2_irq = None
    board_ampfw_size = None
    board_ampcore_num = None
    board_cpu_freq = None
    board_timer_freq = None
    board_irqmax = None

    board_cpucore = "ux900fd"
    try:
        cust_file = args.custsoc

        with open(args.conf, 'r') as conf_file:
            conf_data = json.load(conf_file)

        if 'cpu_config' in conf_data:
            board_cpucore = conf_data['cpu_config'].get("core", "ux900fd")

        if 'general_config' in conf_data:
            general_config = conf_data['general_config']
            if 'ddr' in general_config:
                ddr_config = general_config['ddr']
                if 'base' not in ddr_config:
                    print("ddr base is empty value, use 0x80000000 as default.")
                    ddr_config['base'] = "0x80000000"
                if 'size' not in ddr_config:
                    print("ddr size is empty value, use 0x80000000 as default.")
                    ddr_config['size'] = "0x80000000"
            if 'norflash' in general_config:
                norflash_config = general_config['norflash']
                if 'base' in norflash_config:
                    board_flash_base = norflash_config['base']
                if 'size' in norflash_config:
                    board_flash_size = norflash_config['size']
            if 'iregion' in general_config:
                iregion_config = general_config['iregion']
                if 'base' in iregion_config:
                    board_iregion_base = iregion_config['base']
            if 'uart0' in general_config:
                uart0_config = general_config['uart0']
                if 'base' in uart0_config:
                    board_uart0_base = uart0_config['base']
                if 'irq' in uart0_config:
                    board_uart0_irq = uart0_config['irq']
            if 'uart1' in general_config:
                uart1_config = general_config['uart1']
                if 'base' in uart1_config:
                    board_uart1_base = uart1_config['base']
                if 'irq' in uart1_config:
                    board_uart1_irq = uart1_config['irq']
            if 'qspi0' in general_config:
                qspi0_config = general_config['qspi0']
                if 'base' in qspi0_config:
                    board_qspi0_base = qspi0_config['base']
                if 'irq' in qspi0_config:
                    board_qspi0_irq = qspi0_config['irq']
            if 'qspi2' in general_config:
                qspi2_config = general_config['qspi2']
                if 'base' in qspi2_config:
                    board_qspi2_base = qspi2_config['base']
                if 'irq' in qspi2_config:
                    board_qspi2_irq = qspi2_config['irq']
            if 'cpu_freq' in general_config:
                board_cpu_freq = general_config['cpu_freq']
            if 'timer_freq' in general_config:
                board_timer_freq = general_config['timer_freq']
            if 'ampfw_size' not in general_config:
                general_config['ampfw_size'] = "0x400000"
            if 'amp_core' not in general_config:
                general_config['amp_core'] = "8"
            if 'irqmax' in general_config:
                board_irqmax = general_config['irqmax']
        else:
            print("Warning: json config file maybe empty! use basic default value.")
            ddr_config['base'] = "0x80000000"
            ddr_config['size'] = "0x80000000"
            general_config['ampfw_size'] = "0x400000"
            general_config['amp_core'] = "8"

        board_ddr_base = ddr_config['base']
        board_ddr_size = hex(parse_size(ddr_config['size']))
        if board_flash_size is not None:
            board_flash_size = parse_size(board_flash_size, 'string')
        board_ampfw_size = hex(parse_size(general_config['ampfw_size']))
        board_ampcore_num = general_config['amp_core']

        print("\n>>>Updating opensbi...")
        # update custsoc file
        opensbi_config_mk = "%s/opensbi/config.mk" % (cust_file)
        if os.path.exists(opensbi_config_mk): # v5.10 SDK branch
            variable_name = 'FW_TEXT_START'
            update_freeloader_variable(opensbi_config_mk, variable_name, board_ddr_base)
            replace_in_file(opensbi_config_mk, args.refsoc, args.custsoc)
        else: #v6.x branch
            new_opensbi_file = "%s/opensbi/%s.c" % (cust_file, 'customsoc')
            old_opensbi_file = "%s/opensbi/%s.c" % (cust_file, args.refsoc)
            if not os.path.exists(new_opensbi_file):
                os.rename(old_opensbi_file, new_opensbi_file)
                print(f"Create '{new_opensbi_file}' based on '{old_opensbi_file}'.")
                replace_in_file(new_opensbi_file, args.refsoc, 'customsoc')
                replace_in_file(new_opensbi_file, 'placeholder', args.custsoc)
        print("Note: All custom soc should use customsoc.c for nuclei generic soc support")

        print("\n>>>Updating uboot config...")
        # update uboot defconfig
        matching_cfg_files = glob.glob("%s/uboot_rv*_config" %(cust_file))

        for config_file in matching_cfg_files:
            print("- %s:" % config_file)
            update_uboot_defconfig(config_file)

        print("\n>>>Updating freeloader.mk...");
        # update freeloader.mk
        makefile_path = "%s/freeloader.mk" %(cust_file)
        variable_name = 'DDR_BASE'
        update_freeloader_variable(makefile_path, variable_name, board_ddr_base)

        makefile_path = "%s/freeloader.mk" %(cust_file)
        variable_name = 'FLASH_BASE'
        update_freeloader_variable(makefile_path, variable_name, board_flash_base)

        makefile_path = "%s/freeloader.mk" %(cust_file)
        variable_name = 'FLASH_SIZE'
        update_freeloader_variable(makefile_path, variable_name, board_flash_size)

        makefile_path = "%s/freeloader.mk" %(cust_file)
        variable_name = 'AMPFW_SIZE'
        update_freeloader_variable(makefile_path, variable_name, board_ampfw_size)

        makefile_path = "%s/freeloader.mk" %(cust_file)
        variable_name = 'AMP_START_CORE'
        update_freeloader_variable(makefile_path, variable_name, board_ampcore_num)

        makefile_path = "%s/freeloader.mk" %(cust_file)
        variable_name = 'AMPFW_START_OFFSET'
        reserve_ampmem = int(board_ampfw_size,16) * int(board_ampcore_num)
        if int(board_ddr_size,16) >  reserve_ampmem:
            amp_start_offset = int(board_ddr_size,16) - reserve_ampmem
        else:
            print("generate failed!\n")
            print("Warning: ddr size is less than amp core memory requirements")
            print("ddr size:%s amp core:%s ampfw size:%s" %(hex(int(board_ddr_size,16)), int(board_ampcore_num), hex(int(board_ampfw_size,16))))
            shutil.rmtree(cust_file)
            sys.exit(1)
        update_freeloader_variable(makefile_path, variable_name, hex(amp_start_offset))

        print("\n>>>Updating build.mk...")
        # update build.mk
        makefile_path = "%s/build.mk" %(cust_file)
        variable_name = 'FW_TEXT_START'
        update_build_variable(makefile_path, variable_name, board_ddr_base)

        makefile_path = "%s/build.mk" %(cust_file)
        variable_name = 'UIMAGE_AE_CMD'
        kernel_offset = 0x00400000
        load_addr = int(board_ddr_base, 16) + kernel_offset
        entry_point = int(board_ddr_base, 16) + kernel_offset
        uimage_ae_cmd_val = f"-a 0x{load_addr:08X} -e 0x{entry_point:08X}"
        update_build_variable(makefile_path, variable_name, uimage_ae_cmd_val)

        makefile_path = "%s/build.mk" %(cust_file)
        variable_name = 'QEMU_MACHINE_OPTS'
        update_build_variable(makefile_path, variable_name, "-M nuclei_evalsoc,soc-cfg=conf/%s,download=flashxip -smp 8" %(cust_json_file))

        print("\nUpdating dts...")
        # update dts
        matching_dts_files = glob.glob("%s/nuclei_rv*.dts" %(cust_file))

        for dts_file in matching_dts_files:
            print("- %s:" % dts_file)
            # replace string
            replace_in_file(dts_file, args.refsoc, args.custsoc)
            # update freq
            update_dts_clk_freq(dts_file, 'TIMERCLK_FREQ', board_timer_freq)
            update_dts_clk_freq(dts_file, 'CPUCLK_FREQ', board_cpu_freq)

            # update memory dts node
            ddr_base_int = int(board_ddr_base, 16)
            ddr_base_int_high = (ddr_base_int >> 32) & 0xFFFFFFFF
            ddr_base_int_low = ddr_base_int & 0xFFFFFFFF
            ddr_size_int = int(board_ddr_size, 16) - reserve_ampmem
            ddr_size_int_high = (ddr_size_int >> 32) & 0xFFFFFFFF
            ddr_size_int_low = ddr_size_int & 0xFFFFFFFF
            memory_reg_val = f"0x{ddr_base_int_high:x} 0x{ddr_base_int_low:x} 0x{ddr_size_int_high:x} 0x{ddr_size_int_low:x}"
            update_dts_node(dts_file, 'memory', format(ddr_base_int, 'x'), memory_reg_val)

            if board_iregion_base is not None:
                # update plic dts node
                plic_base_int = int(board_iregion_base, 16) + 0x4000000
                plic_base_int_high = (plic_base_int >> 32) & 0xFFFFFFFF
                plic_base_int_low = plic_base_int & 0xFFFFFFFF
                plic_size_int = 0x4000000
                plic_size_int_high = (plic_size_int >> 32) & 0xFFFFFFFF
                plic_size_int_low = plic_size_int & 0xFFFFFFFF
                plic_reg_val = f"0x{plic_base_int_high:x} 0x{plic_base_int_low:x} 0x{plic_size_int_high:x} 0x{plic_size_int_low:x}"
                update_dts_node(dts_file, 'interrupt-controller', format(plic_base_int, 'x'), plic_reg_val)

                # update clint dts node
                clint_base_int = int(board_iregion_base, 16) + 0x31000
                clint_base_int_high = (clint_base_int >> 32) & 0xFFFFFFFF
                clint_base_int_low = clint_base_int & 0xFFFFFFFF
                clint_size_int = 0x10000
                clint_size_int_high = (clint_size_int >> 32) & 0xFFFFFFFF
                clint_size_int_low = clint_size_int & 0xFFFFFFFF
                clint_reg_val = f"0x{clint_base_int_high:x} 0x{clint_base_int_low:x} 0x{clint_size_int_high:x} 0x{clint_size_int_low:x}"
                update_dts_node(dts_file, 'clint', format(clint_base_int, 'x'), clint_reg_val)

                # update sysrst dts node
                sysrst_base_addr = int(board_iregion_base, 16) + 0x30FF0
                sysrst_high = (sysrst_base_addr >> 32) & 0xFFFFFFFF
                sysrst_low = sysrst_base_addr & 0xFFFFFFFF
                sysrst_reg_val = f"0x{sysrst_high:x} 0x{sysrst_low:x} 0x0 0x0"
                update_dts_node(dts_file, 'sysrst', format(sysrst_base_addr, 'x'), sysrst_reg_val)

            if board_uart0_base is not None:
                # update uart0 dts node
                uart0_base_int = int(board_uart0_base, 16)
                uart0_base_int_high = (uart0_base_int >> 32) & 0xFFFFFFFF
                uart0_base_int_low = uart0_base_int & 0xFFFFFFFF

                uart0_size_int = 0x1000
                uart0_size_int_high = (uart0_size_int >> 32) & 0xFFFFFFFF
                uart0_size_int_low = uart0_size_int & 0xFFFFFFFF

                uart0_reg_val = f"0x{uart0_base_int_high:x} 0x{uart0_base_int_low:x} 0x{uart0_size_int_high:x} 0x{uart0_size_int_low:x}"
                update_dts_node(dts_file, 'uart0', format(uart0_base_int, 'x'), uart0_reg_val, board_uart0_irq)

            if board_uart1_base is not None:
                # update uart1 dts node
                uart1_base_int = int(board_uart1_base, 16)
                uart1_base_int_high = (uart1_base_int >> 32) & 0xFFFFFFFF
                uart1_base_int_low = uart1_base_int & 0xFFFFFFFF
                uart1_size_int = 0x1000
                uart1_size_int_high = (uart1_size_int >> 32) & 0xFFFFFFFF
                uart1_size_int_low = uart1_size_int & 0xFFFFFFFF
                uart1_reg_val = f"0x{uart1_base_int_high:x} 0x{uart1_base_int_low:x} 0x{uart1_size_int_high:x} 0x{uart1_size_int_low:x}"
                update_dts_node(dts_file, 'uart1', format(uart1_base_int, 'x'), uart1_reg_val, board_uart1_irq)

            if board_qspi0_base is not None:
                # update qspi0 dts node
                qspi0_base_int = int(board_qspi0_base, 16)
                qspi0_base_int_high = (qspi0_base_int >> 32) & 0xFFFFFFFF
                qspi0_base_int_low = qspi0_base_int & 0xFFFFFFFF

                qspi0_size_int = 0x1000
                qspi0_size_int_high = (qspi0_size_int >> 32) & 0xFFFFFFFF
                qspi0_size_int_low = qspi0_size_int & 0xFFFFFFFF

                qspi0_reg_val = f"0x{qspi0_base_int_high:x} 0x{qspi0_base_int_low:x} 0x{qspi0_size_int_high:x} 0x{qspi0_size_int_low:x}"
                update_dts_node(dts_file, 'qspi0', format(qspi0_base_int, 'x'), qspi0_reg_val, board_qspi0_irq)

            if board_qspi2_base is not None:
                # update qspi2 dts node
                qspi2_base_int = int(board_qspi2_base, 16)
                qspi2_base_int_high = (qspi2_base_int >> 32) & 0xFFFFFFFF
                qspi2_base_int_low = qspi2_base_int & 0xFFFFFFFF

                qspi2_size_int = 0x1000
                qspi2_size_int_high = (qspi2_size_int >> 32) & 0xFFFFFFFF
                qspi2_size_int_low = qspi2_size_int & 0xFFFFFFFF

                qspi2_reg_val = f"0x{qspi2_base_int_high:x} 0x{qspi2_base_int_low:x} 0x{qspi2_size_int_high:x} 0x{qspi2_size_int_low:x}"
                update_dts_node(dts_file, 'qspi2', format(qspi2_base_int, 'x'), qspi2_reg_val, board_qspi2_irq)
            update_plic_intr_num(dts_file, board_irqmax)

        print("\n>>>Updating uboot.cmd...")
        # update uboot.cmd
        uboot_cmd_file = "%s/uboot.cmd" %(cust_file)
        kernel_load_addr = hex(int(board_ddr_base, 16) + 0x3000000)
        rootfs_load_addr = hex(int(board_ddr_base, 16) + 0x8300000)
        fdt_load_addr = hex(int(board_ddr_base, 16) + 0x8000000)
        update_uboot_cmd(uboot_cmd_file, kernel_load_addr, rootfs_load_addr, fdt_load_addr)

        print("\n>>>Updating openocd config...")
        # update openocd config file
        openocd_cfg_file = "%s/openocd.cfg" %(cust_file)
        workmem_base = hex(int(board_ddr_base, 16))
        workmem_size = hex(0x10000)
        flashxip_base = hex(int(board_flash_base, 16))
        xipnuspi_base = hex(int(board_qspi0_base, 16))
        update_openocd_config(openocd_cfg_file,
            workmem_base=workmem_base,
            workmem_size=workmem_size,
            flashxip_base=flashxip_base,
            xipnuspi_base=xipnuspi_base)

        print("\n===generate successfully!===\n")
        print("Here are the reference build commands for compiling Linux SDK for you:")
        print("$ cd ..")
        print("$ make SOC=%s CORE=%s BOOT_MODE=sd freeloader bootimages" % (args.custsoc, board_cpucore))
        print("$ make SOC=%s CORE=%s BOOT_MODE=sd run_qemu" % (args.custsoc, board_cpucore))
        print("Please adjust the compilation parameters according to your real hardware environment.")
    except Exception as e:
        print(f'Exception occur: {e}')
        # back to orgin working directory,remote generated files
        shutil.rmtree(cust_file)
        print("generate failed!\n")

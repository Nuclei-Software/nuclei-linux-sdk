#!/bin/python3
import re
import json
import glob
import sys
import os
import shutil

def is_uboot_flash_config_format(s):
    pattern = r'^uboot_\w+_flash_config$'
    return bool(re.match(pattern, s))

def update_uboot_defconfig(config_file):
    with open(config_file, 'r') as f:
        defconfig_content = f.readlines()

    updated_content = []
    for line in defconfig_content:
        if 'CONFIG_TEXT_BASE=' in line:
            line = f'CONFIG_TEXT_BASE={uboot_text_base}\n'
            print("%s: Updated with %s" %(config_file, line))
        if 'CONFIG_SYS_TEXT_BASE=' in line:
            line = f'CONFIG_SYS_TEXT_BASE={uboot_text_base}\n'
            print("%s: Updated with %s" %(config_file, line))
        elif 'CONFIG_CUSTOM_SYS_INIT_SP_ADDR=' in line:
            line = f'CONFIG_CUSTOM_SYS_INIT_SP_ADDR={uboot_cust_sys_init_sp_addr}\n'
            print("%s: Updated with %s" %(config_file, line))
        elif 'CONFIG_SYS_LOAD_ADDR=' in line:
            line = f'CONFIG_SYS_LOAD_ADDR={uboot_sys_load_addr}\n'
            print("%s: Updated with %s" %(config_file, line))
        elif 'CONFIG_BOOTCOMMAND=' in line: #update flashboot config bootm
            if is_uboot_flash_config_format(config_file):
                kernel_addr = hex(int(board_sdram_base, 16) + 0x3000000)
                rootfs_addr = hex(int(board_sdram_base, 16) + 0x8300000)
                fdt_addr = hex(int(board_sdram_base, 16) + 0x8000000)
                line = f'CONFIG_BOOTCOMMAND="bootm {kernel_addr} {rootfs_addr} {fdt_addr}"\n'
                print("%s: Updated with %s" %(config_file, line))
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
    print("%s: Updated kernel_addr to %s, rootfs_addr to %s, fdt_addr to %s" %(file_path, kernel_load_address, rootfs_load_address, fdt_load_address))

def update_dts_clk_freq(dts_file_path, macro_name, new_freq_value):
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
    print("%s: Updated %s to %s" %(dts_file_path, macro_name, new_freq_value))

def update_dts_node(dts_file_path, node_name, new_base_address, new_reg_values):
    with open(dts_file_path, 'r') as f:
        dts_content = f.read()

    # 构造正则表达式以匹配整个节点
    pattern_node = re.compile(
        r'({}@(\w+))\s*{{.*?reg\s*=\s*<([^>]*)>;.*?}}'.format(re.escape(node_name)),
        re.DOTALL
    )

    # 搜索匹配的节点
    match = pattern_node.search(dts_content)

    if match:
        # 提取旧的基地址
        old_base_address = match.group(2)

        # 构造新的节点名和准备替换reg属性值
        new_node_name = f"{node_name}@{new_base_address}"
        # 匹配并替换节点名（如果需要同时替换节点名的话）
        dts_content = dts_content.replace(match.group(1), new_node_name, 1)

        # 构造用于替换reg属性的新字符串，并确保只替换目标节点的reg
        reg_pattern = re.compile(rf'reg\s*=\s*<{match.group(3)}>;', re.MULTILINE)
        new_reg_content = reg_pattern.sub(f"reg = <{new_reg_values}>;", dts_content, count=1)

        # 将新的内容写回文件
        with open(dts_file_path, 'w') as f:
            f.write(new_reg_content)
        print(f"{dts_file_path}: Updated  {node_name}@{old_base_address} to {new_node_name}, and updated reg value.")
    else:
        print("Node not found!")


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
        print("%s: Updated %s to %s" %(makefile_path, variable_name, new_value))
    else:
        print("not match %s" % variable_name)

def update_freeloader_variable(makefile_path, variable_name, new_value):
    with open(makefile_path, 'r') as file:
        content = file.read()

    pattern = r'^{}\s*\?\=\s*(.*)'.format(variable_name)
    match = re.search(pattern, content, re.MULTILINE)
    if match:
        new_line = f"{variable_name} ?= {new_value}"
        content = re.sub(pattern, new_line, content, flags=re.MULTILINE)
        with open(makefile_path, 'w') as file:
            file.write(content)
        print("%s: Updated %s to %s" %(makefile_path, variable_name, new_value))
    else:
        print("not match %s" % variable_name)

def replace_in_file(file_path, old_string, new_string):
    # 读取文件内容
    with open(file_path, 'r') as file:
        file_data = file.read()
    print("%s: Replace string %s with %s" %(file_path, old_string, new_string));
    # 替换文件中的指定字符串
    file_data = file_data.replace(old_string, new_string)

    # 写回文件，覆盖原文件内容
    with open(file_path, 'w') as file:
        file.write(file_data)

if len(sys.argv) < 4:
    print("Usage: genconf.py conf.json custsoc refsoc\n"
          "       conf.json: json config file.\n"
          "       refsoc: reference soc config,you can use evalsoc as reference or others.\n"
          "       custsoc: new config files created by genconf.py.\n")
    exit(1)
if not os.path.exists(sys.argv[1]):
    print("%s not exist!\n" % sys.argv[1])
    exit(1)
elif os.path.exists(sys.argv[2]):
    print("%s have exist!\n" % sys.argv[2])
    exit(1)
elif os.path.exists(sys.argv[3]):
    shutil.copytree(sys.argv[3], sys.argv[2])
    print("===start generate %s based on %s===\n" % (sys.argv[2], sys.argv[3]))
else:
    print("%s not exist!\n" % sys.argv[3])
    exit(1)

try:
    # save file path before switch working directory.
    config_file_path = os.path.abspath(sys.argv[1])
    generated_file_path = os.path.abspath(sys.argv[2])
    # switch to custsoc directory
    os.chdir(sys.argv[2])

    with open(config_file_path, 'r') as conf_file:
        conf_data = json.load(conf_file)

    if 'general_config' in conf_data:
        general_config = conf_data['general_config']
        if 'sdram' in general_config:
            sdram_config = general_config['sdram']
            if 'base' not in sdram_config:
                sdram_config['base'] = "0x80000000"  # 或其他合适的默认值
            if 'size' not in sdram_config:
                sdram_config['size'] = "0x80000000"  # 或其他合适的默认值
        if 'norflash' in general_config:
            norflash_config = general_config['norflash']
            if 'base' not in norflash_config:
                norflash_config['base'] = "0x20000000"  # 或其他合适的默认值
            if 'size' not in norflash_config:
                norflash_config['size'] = "32M"  # 设置默认值
        if 'iregion' in general_config:
            iregion_config = general_config['iregion']
            if 'base' not in iregion_config:
                iregion_config['base'] = "0x18000000"  # 或其他合适的默认值
        if 'cpu_freq' not in general_config:
            general_config['cpu_freq'] = "50000000"  # 或其他合适的默认值
        if 'timer_freq' not in general_config:
            general_config['timer_freq'] = "32768"  # 或其他合适的默认值
        if 'ampfw_size' not in general_config:
            general_config['ampfw_size'] = "0x400000"  # 或其他合适的默认值
        if 'amp_core' not in general_config:
            general_config['amp_core'] = "8"  # 或其他合适的默认值

    if 'uboot_config' in conf_data:
        uboot_config = conf_data['uboot_config']
        if 'CONFIG_TEXT_BASE' not in uboot_config:
            uboot_config['CONFIG_TEXT_BASE'] = "0x80200000"  # 或其他合适的默认值

    uboot_text_base = uboot_config['CONFIG_TEXT_BASE']
    uboot_cust_sys_init_sp_addr = uboot_config['CONFIG_TEXT_BASE']
    uboot_sys_load_addr = uboot_config['CONFIG_TEXT_BASE']
    board_sdram_base = sdram_config['base']
    board_sdram_size = sdram_config['size']
    board_flash_base = norflash_config['base']
    board_flash_size = norflash_config['size']
    board_iregion_base = iregion_config['base']
    board_ampfw_size = general_config['ampfw_size']
    board_ampcore_num = general_config['amp_core']
    board_cpu_freq = general_config['cpu_freq']
    board_timer_freq = general_config['timer_freq']

    if ((int(board_sdram_base, 16) & 0xF0000000) != (int(uboot_text_base, 16) & 0xF0000000)
        or (int(board_sdram_base, 16) & 0xF0000000) != (int(uboot_cust_sys_init_sp_addr, 16) & 0xF0000000)
        or (int(board_sdram_base, 16) & 0xF0000000) != (int(uboot_sys_load_addr, 16) & 0xF0000000)):
        print("Warning: sdram base addr is not match with uboot text base addr,please check %s file!" %(sys.argv[1]))
        print("generate failed!\n")
        os.chdir(os.path.dirname(config_file_path))
        shutil.rmtree(generated_file_path)
        exit(1)

    # update custsoc file
    opensbi_config_mk = "%s/opensbi/config.mk" % (generated_file_path)
    if os.path.exists(opensbi_config_mk): # v5.10 SDK branch
        variable_name = 'FW_TEXT_START'
        update_freeloader_variable(opensbi_config_mk, variable_name, board_sdram_base)
        replace_in_file(opensbi_config_mk, sys.argv[3], sys.argv[2])
    else: #v6.x branch
        new_opensbi_file = "%s/opensbi/%s.c" % (generated_file_path, 'customsoc')
        old_opensbi_file = "%s/opensbi/%s.c" % (generated_file_path, sys.argv[3])
        os.rename(old_opensbi_file, new_opensbi_file)
        print(f"file '{old_opensbi_file}' have been renamed to '{new_opensbi_file}'.")
        replace_in_file(new_opensbi_file, sys.argv[3], 'customsoc')

    # update uboot defconfig
    matching_cfg_files = glob.glob('uboot_rv*_config')

    for config_file in matching_cfg_files:
        update_uboot_defconfig(config_file)

    # update freeloader.mk
    makefile_path = 'freeloader.mk'
    variable_name = 'DDR_BASE'
    update_freeloader_variable(makefile_path, variable_name, board_sdram_base)

    makefile_path = 'freeloader.mk'
    variable_name = 'FLASH_BASE'
    update_freeloader_variable(makefile_path, variable_name, board_flash_base)

    makefile_path = 'freeloader.mk'
    variable_name = 'FLASH_SIZE'
    update_freeloader_variable(makefile_path, variable_name, board_flash_size)

    makefile_path = 'freeloader.mk'
    variable_name = 'AMPFW_SIZE'
    update_freeloader_variable(makefile_path, variable_name, board_ampfw_size)

    makefile_path = 'freeloader.mk'
    variable_name = 'AMP_START_CORE'
    update_freeloader_variable(makefile_path, variable_name, board_ampcore_num)

    makefile_path = 'freeloader.mk'
    variable_name = 'AMPFW_START_OFFSET'
    amp_start_offset = int(board_sdram_size,16) - int(board_ampcore_num) * int(board_ampfw_size,16)
    update_freeloader_variable(makefile_path, variable_name, hex(amp_start_offset))

    # update build.mk
    makefile_path = 'build.mk'
    variable_name = 'FW_TEXT_START'
    update_build_variable(makefile_path, variable_name, board_sdram_base)

    makefile_path = 'build.mk'
    variable_name = 'UIMAGE_AE_CMD'
    kernel_offset = 0x00400000
    load_addr = int(board_sdram_base, 16) + kernel_offset
    entry_point = int(board_sdram_base, 16) + kernel_offset
    uimage_ae_cmd_val = f"-a 0x{load_addr:08X} -e 0x{entry_point:08X}"
    update_build_variable(makefile_path, variable_name, uimage_ae_cmd_val)

    makefile_path = 'build.mk'
    variable_name = 'QEMU_MACHINE_OPTS'
    update_build_variable(makefile_path, variable_name, "")

    # update dts
    matching_dts_files = glob.glob('nuclei_rv*.dts')
    reserve_ampmem = int(board_ampfw_size,16) * int(board_ampcore_num)
    for dts_file in matching_dts_files:
        # replace string
        replace_in_file(dts_file, sys.argv[3], sys.argv[2])
        # update freq
        update_dts_clk_freq(dts_file, 'TIMERCLK_FREQ', board_timer_freq)
        update_dts_clk_freq(dts_file, 'CPUCLK_FREQ', board_cpu_freq)

        # update memory dts node
        sdram_base_hex = hex(int(board_sdram_base, 16))
        sdram_size_hex = hex(int(board_sdram_size, 16) - reserve_ampmem)
        memory_reg_val = f"0x0 0x{sdram_base_hex.lstrip('0x')} 0x0 0x{sdram_size_hex.lstrip('0x')}"
        update_dts_node(dts_file, 'memory', sdram_base_hex.lstrip('0x'), memory_reg_val)

        # update plic dts node
        plic_base_hex = hex(int(board_iregion_base, 16) + 0x4000000)
        plic_size_hex = hex(0x4000000)
        plic_reg_val = f"0x0 0x{plic_base_hex.lstrip('0x')} 0x0 0x{plic_size_hex.lstrip('0x')}"
        update_dts_node(dts_file, 'interrupt-controller', plic_base_hex.lstrip('0x'), plic_reg_val)

        # update clint dts node
        clint_base_hex = hex(int(board_iregion_base, 16) + 0x31000)
        clint_size_hex = hex(0xC000)
        clint_reg_val = f"0x0 0x{clint_base_hex.lstrip('0x')} 0x0 0x{clint_size_hex.lstrip('0x')}"
        update_dts_node(dts_file, 'clint', clint_base_hex.lstrip('0x'), clint_reg_val)

    # update uboot.cmd
    uboot_cmd_file = 'uboot.cmd'
    kernel_load_addr = hex(int(board_sdram_base, 16) + 0x3000000)
    rootfs_load_addr = hex(int(board_sdram_base, 16) + 0x8300000)
    fdt_load_addr = hex(int(board_sdram_base, 16) + 0x8000000)
    update_uboot_cmd(uboot_cmd_file, kernel_load_addr, rootfs_load_addr, fdt_load_addr)

    print("===generate successfully!===\n")
except Exception as e:
    print(f'Exception occur: {e}')
    # back to orgin working directory,remote generated files
    os.chdir(os.path.dirname(config_file_path))
    shutil.rmtree(generated_file_path)
    print("===generate failed!===\n")

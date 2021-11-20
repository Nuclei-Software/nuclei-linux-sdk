#
# SPDX-License-Identifier: BSD-2-Clause
#
# Copyright (c) 2020 Nuclei Corporation or its affiliates.
#
# Authors:
#   lujun <lujun@nucleisys.com>
#   hqfang <hqfang@nucleisys.com>
#

# Compiler flags
platform-cppflags-y =
platform-cflags-y =
platform-asflags-y =
platform-ldflags-y =

# Command for platform specific "make run"
platform-runcmd = xl_spike \
  $(build_dir)/platform/nuclei/demosoc/firmware/fw_payload.elf

# Blobs to build
FW_TEXT_START ?= 0xA0000000
FW_DYNAMIC=y
FW_JUMP=y

# This needs to be 2MB aligned for 64-bit system
FW_JUMP_ADDR=$(shell printf "0x%X" $$(($(FW_TEXT_START) + 0x200000)))
FW_JUMP_FDT_ADDR=$(shell printf "0x%X" $$(($(FW_TEXT_START) + 0x8000000)))
FW_PAYLOAD=y
# This needs to be 2MB aligned for 64-bit system
FW_PAYLOAD_OFFSET=0x200000
FW_PAYLOAD_FDT_ADDR=$(FW_JUMP_FDT_ADDR)

#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

export PATH=$PATH:${SCRIPT_DIR}

cd $SCRIPT_DIR
echo "Execute Qemu Testing Now"

set -x
if mount | grep mnt > /dev/null ; then
    umount /mnt
fi
mount /dev/mmcblk0p1 /mnt
qemu-system-riscv64 -M virt,aia=aplic-imsic --enable-kvm -m 1.5G -smp 2 -nographic -kernel Image -initrd rootfs_riscv64.img -virtfs local,path=/,mount_tag=myshare_tag,security_model=none

#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

export PATH=$PATH:${SCRIPT_DIR}

cd $SCRIPT_DIR
echo "Execute Qemu Testing Now"

echo "After guest boot, run this to share the host's /mnt by: mkdir -p /mnt && mount -t 9p -o trans=virtio myshare_tag /mnt"

set -x
if mount | grep mnt > /dev/null ; then
    umount /mnt
fi
mount /dev/mmcblk0p1 /mnt
qemu-system-riscv64 -M virt,aia=aplic-imsic --enable-kvm -m 1900M -smp 2 -nographic -kernel Image -initrd rootfs_riscv64.img -virtfs local,path=/,mount_tag=myshare_tag,security_model=none

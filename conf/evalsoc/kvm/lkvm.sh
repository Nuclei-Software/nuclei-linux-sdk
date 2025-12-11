#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

export PATH=$PATH:${SCRIPT_DIR}

cd $SCRIPT_DIR
echo "Execute LKVM Testing Now"

echo "After guest boot, run this to share the host's /mnt by: mkdir -p /mnt && mount -t 9p -o trans=virtio myshare_tag /mnt"

set -x
if mount | grep mnt > /dev/null ; then
    umount /mnt
fi
mount /dev/mmcblk0p1 /mnt

chmod +x lkvm-static
lkvm-static run --9p /mnt,myshare_tag -m 1900 -c2 -k Image

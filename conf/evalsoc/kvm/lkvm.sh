#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

export PATH=$PATH:${SCRIPT_DIR}

cd $SCRIPT_DIR
echo "Execute KVM Testing Now"

set -x
if mount | grep mnt > /dev/null ; then
    umount /mnt
fi
mount /dev/mmcblk0p1 /mnt
chmod +x lkvm-static
lkvm-static run --9p /mnt,myshare_tag -m 1900 -c2 -k Image

#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}"  )" && pwd  )"

export PATH=$PATH:${SCRIPT_DIR}

cd $SCRIPT_DIR
echo "Execute KVM Testing Now"

set -x
mkdir -p /tmp/myshared/
mount /dev/mmcblk0p1 /tmp/myshared/
chmod +x lkvm-static
lkvm-static run --9p /tmp/myshared,myshare_tag -m 1900 -c2 -k Image

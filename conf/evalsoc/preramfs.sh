#!/bin/env bash

SOCCONF_DIR=$1
ROOTFS_DIR=$2
COPYLIST=$3

if [ "$#" -lt 2  ]; then
    echo "Usage: $0 <SoC Conf Directory> <Rootfs Directory> [Copy File List]"
    exit 1
fi

echo "SOC Configuration Directory is ${SOCCONF_DIR}"
echo "Rootfs Directory is ${ROOTFS_DIR}"

function copy_files() {
    local copyfl=$1
    if [ "x$copyfl" == "x" ] ; then
        echo "No copy file list specified"
        return
    fi
    if [ ! -f $copyfl ] ; then
        copyfl=${SOCCONF_DIR}/${copyfl}
        if [ ! -f $copyfl ] ; then
            echo "Can't find $copyfl, please check!"
            return
        fi
    fi
    while read -r src dst
    do
        if [ "x$src" == "x" ] ; then
            continue
        fi
        if [ "x$dst" == "x" ] ; then
            dst=root
        fi
        if [[ ! -f $src ]] && [[ ! -d $src ]]; then
            src=${SOCCONF_DIR}/$src
            if [[ ! -f $src ]] && [[ ! -d $src ]]; then
                continue
            fi
        fi
        dstdir=${ROOTFS_DIR}/$dst
        mkdir -p $dstdir
        echo "Copy $src to $dstdir"
        if [ -f $src ] ; then
            cp -f $src $dstdir
        else
            cp -rf $src $dstdir
        fi
    done < $copyfl
}

# do copy files specified in $COPYLIST
# $COPYLIST is a file, format as follow
# src dst
copy_files $COPYLIST

# TODO: You can add your extra operations here

exit 0

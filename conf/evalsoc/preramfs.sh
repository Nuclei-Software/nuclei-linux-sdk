#!/bin/env bash

SOCCONF_DIR=$1
ROOTFS_DIR=$2
COPYLIST=$3

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
RESET='\e[0m'

if [ "$#" -lt 2  ]; then
    echo -e "${RED}Usage: $0 <SoC Conf Directory> <Rootfs Directory> [Copy File List]${RESET}"
    exit 1
fi

echo -e "${YELLOW}SOC Configuration Directory is ${SOCCONF_DIR}${RESET}"
echo -e "${YELLOW}Rootfs Directory is ${ROOTFS_DIR}${RESET}"

function copy_files() {
    local copyfl=$1
    if [ "x$copyfl" == "x" ] ; then
        echo -e ${RED}"No copy file list specified${RESET}"
        return
    fi
    if [ ! -f $copyfl ] ; then
        copyfl=${SOCCONF_DIR}/${copyfl}
        if [ ! -f $copyfl ] ; then
            echo -e "${RED}Can't find $copyfl, please check!${RESET}"
            return
        fi
    fi
    echo -e "${YELLOW}Will use $(readlink -f ${copyfl})${RESET}"
    while read -r src dst || [[ -n "$src" ]]
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
        echo -e "${BLUE}Copy $src to $dstdir${RESET}"
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

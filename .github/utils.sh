#!/bin/env bash

function gen_dstimg_names() {
    dstfldname=freeloader_${GITSHA}_${SOC}_${CORE}_${BOOT_MODE}
    dstbootzipname=boot_${GITSHA}_${SOC}_${CORE}_${BOOT_MODE}
    if [[ "$CI_JOB_ID" =~ ^[0-9]+$ ]] ; then
        dstfldname=${dstfldname}_job${CI_JOB_ID}
        dstbootzipname=${dstbootzipname}_job${CI_JOB_ID}
    fi

    if [ "x$CPU_HZ" != "x" ] ; then
        dstfldname=${dstfldname}_${CPU_HZ}Hz
        dstbootzipname=${dstbootzipname}_${CPU_HZ}Hz
    fi

    if [ "x$EXT_SSTC" == "xy" ] ; then
        dstfldname=${dstfldname}_sstc
        dstbootzipname=${dstbootzipname}_sstc
    fi

    if [ "x$HVC_CONSOLE" == "xy" ] ; then
        dstfldname=${dstfldname}_hvc
        dstbootzipname=${dstbootzipname}_hvc
    fi

    if [ "x$CACHE_CTRL" != "x" ] ; then
        dstfldname=${dstfldname}_l1-${CACHE_CTRL}
    fi

    if [ "x$TLB_CTRL" != "x" ] ; then
        dstfldname=${dstfldname}_tlb-${TLB_CTRL}
    fi

    if [ "x$ENABLE_SMP" != "x" ] ; then
        dstfldname=${dstfldname}_smp-${ENABLE_SMP}
    fi

    if [ "x$ENABLE_L2" != "x" ] ; then
        dstfldname=${dstfldname}_l2-${ENABLE_L2}
    fi

    if [ "x$MCACHE_CTL" != "x" ] ; then
        dstfldname=${dstfldname}_mcachectl-${MCACHE_CTL}
    fi

    if [ "x$MTLB_CTL" != "x" ] ; then
        dstfldname=${dstfldname}_mtlbctl-${MTLB_CTL}
    fi

    if [ "x$MMISC_CTL" != "x" ] ; then
        dstfldname=${dstfldname}_mmiscctl-${MMISC_CTL}
    fi

    if [ "x$SPFL1DCTRL1" != "x" ] ; then
        dstfldname=${dstfldname}_pfl1dc1-${SPFL1DCTRL1}
    fi

    if [ "x$SPFL1DCTRL2" != "x" ] ; then
        dstfldname=${dstfldname}_pfl1dc2-${SPFL1DCTRL2}
    fi

    if [ "x$MERGL1DCTRL" != "x" ] ; then
        dstfldname=${dstfldname}_mgl1dc-${MERGL1DCTRL}
    fi

    if [ "x$SIMULATION" != "x" ] && [ "x$SIMULATION" != "x0" ] ; then
        dstfldname=${dstfldname}_sim
    fi
    dstfldname=${dstfldname}.elf
    dstbootzipname=${dstbootzipname}.zip
}

function get_arch() {
    local arch=rv64imac
    if echo "$CORE" | grep -q "fd" > /dev/null ; then
        arch=rv64imafdc
    fi
    echo $arch
}

function replace_dts() {
    local arch=$1
    local old=$2
    local new=$3
    local dts=conf/${SOC}/nuclei_${arch}.dts
    echo "Replace $dts from $old to $new"
    sed -i "s/$old/$new/g" $dts
}

function prepare_sstc_dts() {
    local arch=$(get_arch)
    replace_dts $arch $arch ${arch}_sstc
}

function prepare_hvc_console_dts() {
    local arch=$(get_arch)
    replace_dts $arch ttyNUC0 hvc0
}

function prepare_dts() {
    if [ "x${EXT_SSTC}" == "xy" ] ; then
        prepare_sstc_dts
    fi
    if [ "x${HVC_CONSOLE}" == "xy" ] ; then
        prepare_hvc_console_dts
    fi
}

function reset_dts() {
    local arch=$(get_arch)
    local dts=conf/${SOC}/nuclei_${arch}.dts
    # if modified, then reset to default version
    if git status -s $dts | grep dts > /dev/null 2>&1 ; then
        echo "Reset dts $dts to unmodified version in git"
        git checkout -- $dts
    else
        echo "No need to reset dts $dts"
    fi
}

function link_latest_freeloader() {
    local tag=latest
    if [ "x${CI_COMMIT_BRANCH}" == "x" ] ; then
        echo "Maybe a tag commit or merge request commit, ignore it!"
        return
    fi
    if [ "x${CI_COMMIT_BRANCH}" == "xdev_nuclei_6.1" ] ; then
        tag=latest_6.1
    elif [ "x${CI_COMMIT_BRANCH}" != "xdev_nuclei_next" ] ; then
        tag=$CI_COMMIT_REF_SLUG
    fi
    echo "Link $tag to $SYNCDIR for ${CI_COMMIT_BRANCH}"
    rm -f $SHARELOC/$tag
    pushd $SHARELOC
    ln -s $GITSHA $tag
}

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

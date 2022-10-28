#!/bin/env bash

SOC=${SOC:-demosoc}
CORE=${CORE:-ux900}
BOOT_MODE=${BOOT_MODE:-sd}
MAKEOPTS=${MAKEOPTS:-""}
DRYRUN=${DRYRUN:-0}
DOBUILD=${DOBUILD:-1}

GITSHA=${GITSHA:-$(git describe --always)}

SDKSYNCROOT=/home/share/devtools/linuxsdk
FLDROOT=${SDKSYNCROOT}/local/$(whoami)
BOOTROOT=${SDKSYNCROOT}/local/$(whoami)
SYSENVROOT=${SDKSYNCROOT}/trigger

# eval MAKEOPTS to overwrite variable of SOC/CORE/BOOT_MODE
if [ "x$MAKEOPTS" !=  "x" ] ; then
    echo "MAKEOPTS=$MAKEOPTS"
    eval export $MAKEOPTS
fi

if [[ "$CI_PIPELINE_ID" =~ ^[0-9]+$ ]] ; then
    echo "Triggered by gitlab ci runner, pipeline id is $CI_PIPELINE_ID"
    PIPELINEDIR=${SDKSYNCROOT}/pipelines/${CI_PIPELINE_ID}
    BOOTROOT=${PIPELINEDIR}
    FLDROOT=${PIPELINEDIR}
else
    echo "Triggered locally via $(whoami)"
fi

echo "Final generated freeloader will be copy to ${FLDROOT}"
if [ ! -d ${FLDROOT} ] ; then
    mkdir -p ${FLDROOT}
fi
echo "Final generated bootimages will be copy to ${BOOTROOT}"
if [ ! -d ${BOOTROOT} ] ; then
    mkdir -p ${BOOTROOT}
fi

# get SYSENV, this is a text file contains some variable
# since manual job of gitlab is not able to retrigger it with inputs
# so we use a local share environment file accessable in shared shell
# runner.
# sample content
# SPFL1DCTRL1=0x1f
# SIMULATION=1
# CACHE_CTRL=0x10001
SYSENV=${SYSENV:-${SYSENVROOT}/build_${CORE}_${BOOT_MODE}.env}

if [ -f ${SYSENV} ] ; then
    echo "Current share environment file for this build is ${SYSENV}"
    echo "If you to rerun this manual job, please change the content of ${SYSENV}"
    echo "Here is the content in it, now source it"
    cat ${SYSENV}
    source ${SYSENV}
else
    echo "Unable to find system environment file ${SYSENV} for this build"
    echo "Please make sure it exist, if you want to overwrite your build environment"
fi

# after sourcing ${SYSENV}, the build environment variable might change
# such as SOC/CORE/BOOT_MODE

echo "Git commit is $GITSHA"

srcfld=work/${SOC}/freeloader/freeloader.elf
srcbootzip=work/${SOC}/boot.zip

dstfld=$FLDROOT/freeloader_${GITSHA}_${SOC}_${CORE}_${BOOT_MODE}
dstbootzip=$BOOTROOT/boot_${GITSHA}_${SOC}_${CORE}_${BOOT_MODE}

if [[ "$CI_JOB_ID" =~ ^[0-9]+$ ]] ; then
    dstfld=${dstfld}_job${CI_JOB_ID}
    dstbootzip=${dstbootzip}_job${CI_JOB_ID}
fi

if [ "x$CPU_HZ" != "x" ] ; then
    dstfld=${dstfld}_${CPU_HZ}Hz
    dstbootzip=${dstbootzip}_${CPU_HZ}Hz
fi

if [ "x$CACHE_CTRL" != "x" ] ; then
    dstfld=${dstfld}_l1-${CACHE_CTRL}
fi

if [ "x$TLB_CTRL" != "x" ] ; then
    dstfld=${dstfld}_tlb-${TLB_CTRL}
fi

if [ "x$ENABLE_SMP" != "x" ] ; then
    dstfld=${dstfld}_smp-${ENABLE_SMP}
fi

if [ "x$ENABLE_L2" != "x" ] ; then
    dstfld=${dstfld}_l2-${ENABLE_L2}
fi

if [ "x$SPFL1DCTRL1" != "x" ] ; then
    dstfld=${dstfld}_pf-${SPFL1DCTRL1}
fi

if [ "x$SIMULATION" != "x" ] && [ "x$SIMULATION" != "x0" ] ; then
    dstfld=${dstfld}_sim
fi

dstfld=${dstfld}.elf
dstbootzip=${dstbootzip}.zip


if [ "x$DOBUILD" == "x1" ] ; then
    echo "Build freeloader and boot images"
    make bootimages
    make freeloader
fi

if [ -d $FLDROOT ] && [ -d $BOOTROOT ] ; then
    echo "Freeloader and boot root exist, prepare to copy to internal place!"
else
    echo "Can't locate freeloader and boot root directory"
    exit 1
fi

if [ -f $srcfld ] ; then
    echo "Copy freeloader $srcfld -> $dstfld"
    if [ "x$DRYRUN" == "x0" ] ; then
        cp -f $srcfld $dstfld
    fi
fi

if [ -f $srcbootzip ] ; then
    echo "Copy bootzip $srcbootzip -> $dstbootzip"
    if [ "x$DRYRUN" == "x0" ] ; then
        cp -f $srcbootzip $dstbootzip
    fi
fi

exit 0

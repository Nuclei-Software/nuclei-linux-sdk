#!/bin/env bash

SOC=${SOC:-demosoc}
CORE=${CORE:-ux900}
BOOT_MODE=${BOOT_MODE:-sd}
MAKEOPTS=${MAKEOPTS:-""}
DRYRUN=${DRYRUN:-0}
DOBUILD=${DOBUILD:-1}

GITSHA=${GITSHA:-$(git describe --always)}

FLDROOT=/home/share/devtools/linuxsdk/freeloader
BOOTROOT=/home/share/devtools/linuxsdk/boot

# eval MAKEOPTS to overwrite variable of SOC/CORE/BOOT_MODE
if [ "x$MAKEOPTS" !=  "x" ] ; then
    echo "MAKEOPTS=$MAKEOPTS"
    eval export $MAKEOPTS
fi

echo "Git commit is $GITSHA"

srcfld=work/${SOC}/freeloader/freeloader.elf
srcbootzip=work/${SOC}/boot.zip

dstfld=$FLDROOT/freeloader_${GITSHA}_${SOC}_${CORE}_${BOOT_MODE}
dstbootzip=$BOOTROOT/boot_${GITSHA}_${SOC}_${CORE}_${BOOT_MODE}

if [ "x$CPU_HZ" != "x" ] ; then
    dstfld=${dstfld}_${CPU_HZ}Hz
    dstbootzip=${bootzip}_${CPU_HZ}Hz
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

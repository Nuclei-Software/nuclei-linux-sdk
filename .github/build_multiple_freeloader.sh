#!/bin/env bash

SCRIPTDIR=$(dirname $(readlink -f $BASH_SOURCE))
SCRIPTDIR=$(readlink -f $SCRIPTDIR)

SOC=${SOC:-evalsoc}
CORE=${CORE:-ux900fd}
BOOT_MODE=${BOOT_MODE:-sd}
SELVAR0=${SELVAR0:-CPU_HZ}
VARLIST0=${VARLIST0:-"16000000,50000000"}
SELVAR1=${SELVAR1:-SPFL1DCTRL1}
VARLIST1=${VARLIST1:-"0x0"}
GITSHA=${GITSHA:-$(git describe --always)}
MAKEOPTS=${MAKEOPTS:-""}
DRYRUN=${DRYRUN:-0}
SHARELOC=${SHARELOC:-/home/xl_ci/linuxsdk}

# eval MAKEOPTS to overwrite variable of SOC/CORE/BOOT_MODE
if [ "x$MAKEOPTS" !=  "x" ] ; then
    echo "MAKEOPTS=$MAKEOPTS"
    eval export $MAKEOPTS
fi

echo "Git commit is $GITSHA"

if [[ "$CI_JOB_ID" =~ ^[0-9]+$ ]] ; then
    echo "Create sync directory"
    SYNCDIR=$SHARELOC/$GITSHA
    mkdir -p $SYNCDIR
fi

source $SCRIPTDIR/utils.sh

for var0 in ${VARLIST0//,/ }
do
    for var1 in ${VARLIST1//,/ }
    do
        echo "Build freeloader for $MAKEOPTS $SELVAR0=$var0 $SELVAR1=$var1"
        eval export $SELVAR0=$var0 $SELVAR1=$var1
        # get freeloader and boot zip suffix
        gen_dstimg_names
        frldelf=work/${SOC}/${dstfldname}
        runcmd="make freeloader && cp -f work/${SOC}/freeloader/freeloader.elf ${frldelf}"
        echo $runcmd
        if [ "x$DRYRUN" == "x0" ] ; then
            prepare_dts
            eval $runcmd
            reset_dts
        fi
        unset $SELVAR0 $SELVAR1
        if [ "x$SYNCDIR" != "x" ] ; then
            echo "Sync freeloader $frldelf to ${SYNCDIR}"
            cp -f $frldelf $SYNCDIR/
        fi
    done
done

if [ "x$SYNCDIR" != "x" ] && [ "x$DRYRUN" == "x0" ] ; then
    link_latest_freeloader
fi

exit 0

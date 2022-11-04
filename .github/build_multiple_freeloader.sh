#!/bin/env bash

SOC=${SOC:-demosoc}
CORE=${CORE:-ux900}
BOOT_MODE=${BOOT_MODE:-sd}
SELVAR0=${SELVAR0:-CPU_HZ}
VARLIST0=${VARLIST0:-"16000000,100000000"}
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

for var0 in ${VARLIST0//,/ }
do
    for var1 in ${VARLIST1//,/ }
    do
        echo "Build freeloader for $MAKEOPTS $SELVAR0=$var0 $SELVAR1=$var1"
        eval export $SELVAR0=$var0 $SELVAR1=$var1
        frlname=freeloader_${GITSHA}_${SOC}_${CORE}_${BOOT_MODE}
        if [ "$SELVAR0" != "SOC" ] && [ "$SELVAR0" != "CORE" ] && [ "$SELVAR0" != "BOOT_MODE" ] ; then
            frlname=${frlname}_${SELVAR0,,}-${var0}
        fi
        if [ "$SELVAR1" != "SOC" ] && [ "$SELVAR1" != "CORE" ] && [ "$SELVAR1" != "BOOT_MODE" ] ; then
            frlname=${frlname}_${SELVAR1,,}-${var1}
        fi
        frldelf=work/${SOC}/${frlname}.elf
        runcmd="make freeloader && cp -f work/${SOC}/freeloader/freeloader.elf ${frldelf}"
        echo $runcmd
        if [ "x$DRYRUN" == "x0" ] ; then
            eval $runcmd
        fi
        unset $SELVAR0 $SELVAR1
        if [ "x$SYNCDIR" != "x" ] ; then
            echo "Sync freeloader $frldelf to ${SYNCDIR}"
            cp -f $frldelf $SYNCDIR/
        fi
    done
done

if [ "x$SYNCDIR" != "x" ] ; then
    echo "Link latest to $SYNCDIR"
    if [ "x${CI_COMMIT_BRANCH}" == "xdev_nuclei_next" ]
        rm -f $SHARELOC/latest
        pushd $SHARELOC
        ln -s $GITSHA latest
        popd
    fi
fi

exit 0

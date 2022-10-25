#!/bin/env bash

SELVAR=${SELVAR:-CPU_HZ}
VARLIST=${VARLIST:-"16000000,100000000"}
GITSHA=${GITSHA:-$(git describe --always)}
MAKEOPTS=${MAKEOPTS:-""}
DRYRUN=${DRYRUN:-0}

SOC=demosoc
CORE=ux900
BOOT_MODE=sd

# eval MAKEOPTS to overwrite variable of SOC/CORE/BOOT_MODE
if [ "x$MAKEOPTS" !=  "x" ] ; then
    eval $MAKEOPTS
fi

echo "Git commit is $GITSHA"

for var in ${VARLIST//,/ }
do
    echo "Build freeloader for $MAKEOPTS $SELVAR=$var"
    eval $SELVAR=$var
    frlname=freeloader_${GITSHA}_${SOC}_${CORE}_${BOOT_MODE}
    if [ "$SELVAR" != "SOC" ] && [ "$SELVAR" != "CORE" ] && [ "$SELVAR" != "BOOT_MODE" ] ; then
        frlname=${frlname}_${SELVAR,,}-${var}
    fi
    frldelf=work/${SOC}/${frlname}.elf
    runcmd="make freeloader && cp -f work/${SOC}/freeloader/freeloader.elf ${frldelf}"
    echo $runcmd
    if [ "x$DRYRUN" == "x0" ] ; then
        eval $runcmd
    fi
done

exit 0

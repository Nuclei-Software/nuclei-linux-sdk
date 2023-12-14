#!/bin/env bash

SCRIPTDIR=$(dirname $(readlink -f $BASH_SOURCE))
SCRIPTDIR=$(readlink -f $SCRIPTDIR)

SOC=${SOC:-evalsoc}
CORE=${CORE:-ux900fd}
BOOT_MODE=${BOOT_MODE:-sd}
MAKEOPTS=${MAKEOPTS:-""}
DRYRUN=${DRYRUN:-0}
DOBUILD=${DOBUILD:-1}
DOSYMLINK=${DOSYMLINK:-1}
BUILDBOOTIMAGES=${BUILDBOOTIMAGES:-1}
OVERRIDEROOT=${OVERRIDEROOT:-}

GITSHA=${GITSHA:-$(git describe --always)}

SDKSYNCROOT=/home/share/devtools/linuxsdk
FLDROOT=${SDKSYNCROOT}/local/$(whoami)
BOOTROOT=${SDKSYNCROOT}/local/$(whoami)
SYSENVROOT=${SDKSYNCROOT}/trigger/$(whoami)

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

if [ "x$OVERRIDEROOT" != "x$OVERRIDEROOT" ] ; then
    echo "Using overwrite freeloader, boot zip, sys environment root"
    BOOTROOT=${OVERRIDEROOT}
    FLDROOT=${OVERRIDEROOT}
    SYSENVROOT=${OVERRIDEROOT}
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
    # Each variable or function that is created or modified is given the export attribute and marked for export to the environment of subsequent commands.
    set -a
    source ${SYSENV}
    set +a
else
    echo "Unable to find system environment file ${SYSENV} for this build"
    echo "Please make sure it exist, if you want to overwrite your build environment"
fi

# after sourcing ${SYSENV}, the build environment variable might change
# such as SOC/CORE/BOOT_MODE

echo "Git commit is $GITSHA"

srcfld=work/${SOC}/freeloader/freeloader.elf
srcbootzip=work/${SOC}/boot.zip

source $SCRIPTDIR/utils.sh
# get freeloader and boot zip suffix
gen_dstimg_names

dstfld=$FLDROOT/${dstfldname}
dstbootzip=$BOOTROOT/${dstbootzipname}

function prepare_workdir() {
    local workdir=work/${SOC}
    local realworkdir=work/${SOC}_${CORE}
    if [ -L $workdir ] && [ "x$DOSYMLINK" == "x1" ] ; then
        echo "This is a symbolic path, update the link from $workdir -> $realworkdir, sleep 3s to confirm it"
        sleep 3
        rm -f $workdir
        mkdir -p $realworkdir
        ln -s $(basename $realworkdir) $workdir
    fi
}


if [ "x$DOBUILD" == "x1" ] ; then
    echo "Build freeloader and boot images"
    prepare_workdir
    prepare_dts
    if [ "x${BUILDBOOTIMAGES}" == "x1" ] ; then
        echo "Build boot images now"
        make bootimages
    fi
    echo "Build freeloader now"
    make freeloader
    reset_dts
fi

if [ -d $FLDROOT ] && [ -d $BOOTROOT ] ; then
    echo "Freeloader and boot root exist, prepare to copy to internal place!"
else
    echo "Can't locate freeloader and boot root directory"
    exit 1
fi

if [ -f ${SYSENV} ] ; then
    echo "Current share environment file for this build is ${SYSENV}"
    echo "If you to rerun this manual job, please change the content of ${SYSENV}"
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

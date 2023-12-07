test -z "${bootloc}"   && setenv bootloc .
test -z "${kernelimg}" && setenv kernelimg ${bootloc}/uImage.lz4
test -z "${rootfsimg}" && setenv rootfsimg ${bootloc}/uInitrd.lz4
test -z "${dtbimg}"    && setenv dtbimg ${bootloc}/kernel.dtb
test -z "${itbimg}"    && setenv itbimg ${bootloc}/image.itb

if test -e mmc 0 ${itbimg} ; then
    echo "Loading FIT Image"
    fatload mmc 0 0x204000000 ${itbimg}
    echo "Starts booting from SD using FIT Image"
    bootm 0x204000000
fi

echo "Boot images located in ${bootloc}"
echo "Loading kernel: ${kernelimg}"
fatload mmc 0 0x203000000 ${kernelimg}
echo "Loading ramdisk: ${rootfsimg}"
fatload mmc 0 0x208300000 ${rootfsimg}
if test -e mmc 0 ${dtbimg} ; then
    echo "Loading dtb: ${dtbimg}"
    fatload mmc 0 0x208000000 ${dtbimg}
else
    echo "${dtbimg} not found, ignore it"
fi
echo "Starts booting from SD"
bootm 0x203000000 0x208300000 0x208000000

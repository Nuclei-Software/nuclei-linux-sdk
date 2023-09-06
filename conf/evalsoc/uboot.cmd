test -z "${bootloc}"   && setenv bootloc .
test -z "${kernelimg}" && setenv kernelimg ${bootloc}/uImage.lz4
test -z "${rootfsimg}" && setenv rootfsimg ${bootloc}/uInitrd.lz4
test -z "${dtbimg}"    && setenv dtbimg ${bootloc}/kernel.dtb

echo "Boot images located in ${bootloc}"
echo "Loading kernel: ${kernelimg}"
fatload mmc 0 0x83000000 ${kernelimg}
echo "Loading ramdisk: ${rootfsimg}"
fatload mmc 0 0x88300000 ${rootfsimg}
if test -e mmc 0 ${dtbimg} ; then
    echo "Loading dtb: ${dtbimg}"
    fatload mmc 0 0x88000000 ${dtbimg}
else
    echo "${dtbimg} not found, ignore it"
fi
echo "Starts booting from SD"
bootm 0x83000000 0x88300000 0x88000000

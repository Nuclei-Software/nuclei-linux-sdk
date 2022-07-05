echo 'Loading kernel'
fatload mmc 0 0xa1000000 uImage.lz4
echo 'Loading ramdisk'
fatload mmc 0 0xa8300000 uInitrd.lz4
if test -e mmc 0 kernel.dtb ; then
    echo 'Loading dtb'
    fatload mmc 0 0xa8000000 kernel.dtb
else
    echo 'kernel.dtb not found, ignore it'
fi
echo 'Starts booting from SD'
bootm 0xa1000000 0xa8300000 0xa8000000

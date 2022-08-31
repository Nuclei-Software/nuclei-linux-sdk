echo 'Loading kernel'
fatload mmc 0 0x41000000 uImage.lz4
echo 'Loading ramdisk'
fatload mmc 0 0x48300000 uInitrd.lz4
if test -e mmc 0 kernel.dtb ; then
    echo 'Loading dtb'
    fatload mmc 0 0x48000000 kernel.dtb
else
    echo 'kernel.dtb not found, ignore it'
fi
echo 'Starts booting from SD'
bootm 0x41000000 0x48300000 0x48000000
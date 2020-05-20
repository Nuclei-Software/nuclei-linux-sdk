echo 'Loading kernel'
fatload mmc 0 0xa1000000 uImage.lz4
echo 'Loading ramdisk'
fatload mmc 0 0xa8300000 uInitrd.gz
setenv bootargs 'earlycon=sbi'
echo 'Starts booting from SD'
bootm 0xa1000000 0xa8300000 0xa8000000

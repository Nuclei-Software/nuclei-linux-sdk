test -z "${bootloc}"   && setenv bootloc .
test -z "${kernelimg}" && setenv kernelimg ${bootloc}/kernel_rootfs.itb

echo "Boot images located in ${bootloc}"
echo "Loading kernel: ${kernelimg}"
fatload mmc 0 0x83000000 ${kernelimg}
echo "Starts booting from SD"
bootm 0x83000000:kernel 0x83000000:ramdisk 0x88000000

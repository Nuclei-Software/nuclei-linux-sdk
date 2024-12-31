test -z "${bootloc}"   && setenv bootloc .
test -z "${kernelimg}" && setenv kernelimg ${bootloc}/kernel.itb

echo "Boot images located in ${bootloc}"
echo "Loading kernel: ${kernelimg}"
fatload mmc 0 0xc3000000 ${kernelimg}
echo "Starts booting from SD"
bootm 0xc3000000:kernel 0xc3000000:ramdisk 0xc8000000

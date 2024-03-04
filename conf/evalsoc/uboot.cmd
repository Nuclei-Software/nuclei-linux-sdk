test -z "${bootloc}"   && setenv bootloc .
test -z "${kernel_fit}" && setenv kernel_fit ${bootloc}/kernel_rootfs.itb
setenv kernel_fit_load_addr 0x83000000

echo "Boot images located in ${bootloc}"
echo "Loading fit kernel: ${kernel_fit}"
fatload mmc 0 ${kernel_fit_load_addr} ${kernel_fit}
echo "Starts booting from SD"
# If use kernel.dtb in kernel_rootfs.itb, you should pass 0x8300000:fdt as param,
# and kernel.dtb load address is configured in load = <0x0 0x89000000> of fdt node in uboot.its.
# else use dtb from spl.itb and pass 0x88000000 as dtb address.
# bootm ${kernel_fit_load_addr}:kernel ${kernel_fit_load_addr}:ramdisk ${kernel_fit_load_addr}:fdt

# use dtb from spl.itb default
bootm ${kernel_fit_load_addr}:kernel ${kernel_fit_load_addr}:ramdisk 0x88000000

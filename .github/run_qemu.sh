cd nuclei-linux-sdk
timeout --foreground -s SIGTERM 4m make run_qemu > >(tee run_qemu.log)

# check pass or not
if cat run_qemu.log | grep "Run /init" ; then
    echo "Kernel boot successfully" ;
else
    echo "Kernel boot failed"
    exit 1;
fi;
if cat run_qemu.log | grep "Welcome to" ; then
    echo "Pass simulation" && exit 0;
else
    echo "Failed init process" && exit 1;
fi;
exit 0

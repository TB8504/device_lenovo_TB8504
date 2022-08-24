#!/system/bin/sh

echo 1 > /dev/wcnss_wlan
sleep 10
echo sta > /sys/module/wlan/parameters/fwpath

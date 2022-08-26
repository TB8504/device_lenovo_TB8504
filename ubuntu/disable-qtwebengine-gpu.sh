#!/bin/sh
# Disable GPU compositing for QtWebEngine on Android 7.1 and older devices
# This file is part of lxc-android-config
if [ -f /system/build.prop ]; then
    SDK_VERSION=$(getprop ro.build.version.sdk)
    DEVICE=$(getprop ro.product.device)
    if test "$SDK_VERSION" -lt 28; then
        DISABLE_GPU_COMPOSITING="--disable-gpu-compositing"
    else
        COMPOSITOR_BLOCKLIST="bacon A0001 hammerhead FP2 fp2 TB-8504X TB-8504F"
        for d in $COMPOSITOR_BLOCKLIST; do
            if [ "$d" = "$DEVICE" ]; then
                DISABLE_GPU_COMPOSITING="--disable-gpu-compositing"
            fi
        done
    fi

    BLOCKLIST="krillin vegetahd arale mako flo deb TB-8504X TB-8504F"
    for d in $BLOCKLIST; do
        if [ "$d" = "$DEVICE" ]; then
            DISABLE_GPU="--disable-gpu"
        fi
    done
fi
export QTWEBENGINE_CHROMIUM_FLAGS="--disable-viz-display-compositor $DISABLE_GPU_COMPOSITING $DISABLE_GPU"

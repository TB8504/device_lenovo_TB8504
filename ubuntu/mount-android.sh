#!/bin/bash

# On systems with A/B partition layout, current slot is provided via cmdline parameter.
ab_slot_suffix=$(grep -o 'androidboot\.slot_suffix=..' /proc/cmdline |  cut -d "=" -f2)
[ ! -z "$ab_slot_suffix" ] && echo "A/B slot system detected! Slot suffix is $ab_slot_suffix"

find_partition_path() {
    label=$1
    path="/dev/$label"
    # In case fstab provides /dev/mmcblk0p* lines
    for dir in by-partlabel by-name by-label ../mapper by-path by-uuid by-partuuid by-id; do
        # On A/B systems not all of the partitions are duplicated, so we have to check with and without suffix
        if [ -e "/dev/disk/$dir/$label$ab_slot_suffix" ]; then
            path="/dev/disk/$dir/$label$ab_slot_suffix"
            break
        elif [ -e "/dev/disk/$dir/$label" ]; then
            path="/dev/disk/$dir/$label"
            break
        fi
    done
    echo $path
}

parse_mount_flags() {
    org_options="$1"
    options=""
    for i in $(echo $org_options | tr "," "\n"); do
        [[ "$i" =~ "context" ]] && continue
        options+=$i","
    done
    options=${options%?}
    echo $options
}

if [ -e /dev/.halium_jumpercable ]; then
    echo "jumpercable boot detected, retriggering udev setup"
    udevadm trigger --action=add
    udevadm settle
fi

echo "checking for vendor mount point"

vendor_images="/userdata/vendor.img /var/lib/lxc/android/vendor.img"
for image in $vendor_images; do
    if [ -e $image ]; then
        echo "mounting vendor from $image"
        mount $image /vendor -o ro
    fi
done

if ! mountpoint -q -- /vendor; then
    sys_vendor="/sys/firmware/devicetree/base/firmware/android/fstab/vendor"
    default_vendor=$(find_partition_path "vendor")
    if [ -e $sys_vendor ]; then
        label=$(awk -F/ '{print $NF}' < $sys_vendor/dev)
        path=$(find_partition_path "$label")
        [ ! -e "$path" ] && echo "Error vendor not found" && exit
        type=$(cat $sys_vendor/type)
        options=$(parse_mount_flags "$(cat "$sys_vendor/mnt_flags")")
    elif [ -n "$default_vendor" ] && [ -e "$default_vendor" ]; then
        # default to a partition labeled "vendor" even if not in DT fstab
        path=$default_vendor
        type=ext4
        options=ro
    fi
    echo "mounting $path as /vendor"
    mount "$path" /vendor -t "$type" -o "$options"
fi

# mount tmpfs for vendor mounts
mount -t tmpfs tmpfs /mnt

sys_persist="/sys/firmware/devicetree/base/firmware/android/fstab/persist"
if [ -e $sys_persist ]; then
    label=$(cat $sys_persist/dev | awk -F/ '{print $NF}')
    path=$(find_partition_path $label)
    # [ ! -e "$path" ] && echo "Error persist not found" && exit
    type=$(cat $sys_persist/type)
    options=$(parse_mount_flags $(cat $sys_persist/mnt_flags))
    if [ -e $sys_persist/mnt_point ]; then
        target=`cat $sys_persist/mnt_point`
        echo "mounting $path as $target"
        mkdir -p $target
        mount $path $target -t $type -o $options
    else
        # if there is no indication that persist should be mounted elsewhere, default to old location
        echo "mounting $path as /persist and /mnt/vendor/persist"
        mount $path /persist -t $type -o $options
        mkdir -p /mnt/vendor/persist
        mount $path /mnt/vendor/persist -t $type -o $options
    fi
fi

if [ -d "/apex" ]; then
    mount -t tmpfs tmpfs /apex

    for path in "/system/apex/com.android.runtime.release" "/system/apex/com.android.runtime.debug" "/system/apex/com.android.runtime"; do
        if [ -e "$path" ]; then
            mkdir -p /apex/com.android.runtime
            mount -o bind $path /apex/com.android.runtime
            break
        fi
    done

    for path in "/system/apex/com.android.art.release" "/system/apex/com.android.art.debug" "/system/apex/com.android.art"; do
        if [ -e "$path" ]; then
            mkdir -p /apex/com.android.art
            mount -o bind $path /apex/com.android.art
            break
        fi
    done
fi

# List all fstab files
fstab=$(ls /vendor/etc/fstab*)
[ -z "$fstab" ] && echo "fstab not found" && exit

echo "checking fstab $fstab for additional mount points"

# If there's more than one file, this will simply concatinate them together
cat ${fstab} | while read line; do
    set -- $line

    # stop processing if we hit the "#endhalium" comment in the file
    echo $1 | egrep -q "^#endhalium" && break

    # Skip any unwanted entry
    echo $1 | egrep -q "^#" && continue
    ([ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]) && continue
    ([ "$2" = "/system" ] || [ "$2" = "/data" ] || [ "$2" = "/" ] \
    || [ "$2" = "auto" ] || [ "$2" = "/vendor" ] || [ "$2" = "none" ] \
    || [ "$2" = "/misc" ] || [ "$2" = "/product" ]) && continue
    ([ "$3" = "emmc" ] || [ "$3" = "swap" ] || [ "$3" = "mtd" ]) && continue

    label=$(echo $1 | awk -F/ '{print $NF}')
    [ -z "$label" ] && continue

    echo "checking mount label $label"

    path=$(find_partition_path $label)

    if [ ! -e "$path" ]; then
        partition_images="/userdata/$label.img /var/lib/lxc/android/$label.img"
        for image in $partition_images; do
            if [ -e $image ]; then
                path="$image"
            fi
        done
    fi

    [ ! -e "$path" ] && continue

    mkdir -p $2
    echo "mounting $path as $2"
    mount $path $2 -t $3 -o $(parse_mount_flags $4)
done

# some mounts may fail, but this is not fatal, so make sure to exit normally
exit 0

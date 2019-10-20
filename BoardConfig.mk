#
# Copyright (C) 2019 The LineageOS Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# inherit from common tb-common
-include device/lenovo/tb-common/BoardConfigCommon.mk

DEVICE_PATH := device/lenovo/TB8504

# Asserts
TARGET_OTA_ASSERT_DEVICE := TB-8504X,TB-8504F,tb-8504x,tb-8504f,tb_8504

# Bluetooth
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := $(DEVICE_PATH)/bluetooth

# Camera
TARGET_USES_QTI_CAMERA_DEVICE := true
TARGET_TS_MAKEUP := true

# Init
TARGET_INIT_VENDOR_LIB := libinit_lenovo_tb8504
TARGET_RECOVERY_DEVICE_MODULES := libinit_lenovo_tb8504

# Kernel
TARGET_KERNEL_CONFIG := lineageos_tb8504_defconfig

# Partitions
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 4080218112
BOARD_USERDATAIMAGE_PARTITION_SIZE := 9921059840 # 9921076224 - 16384

# SELinux
BOARD_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy

# Inherit from the proprietary version
-include vendor/lenovo/TB8504/BoardConfigVendor.mk

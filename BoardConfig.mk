# Platform
TARGET_BOARD_PLATFORM := rpi

# Target Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := cortex-a76

# 64-bit only (core_64_bit_only.mk in rpi5.mk): no secondary 32-bit architecture.

# Graphics & Display
# HWUI stays on OpenGL ES until it is validated on V3DV. The previous Vulkan driver,
# SwiftShader, exposed fewer queues than VulkanManager requires
# (kRequestedQueueCount=2) -> SystemUI abort.
# false -> ro.hwui.use_vulkan=false (sysprop_config.mk) -> HWUI renderer skiagl (OpenGL ES).
TARGET_USES_VULKAN := false

# SEPolicy
BOARD_SEPOLICY_DIRS += device/rpi/rpi5/sepolicy
PRODUCT_FULL_TREBLE_OVERRIDE := true

# Kernel Configuration
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
# Kernel command line. Single source for cmdline.txt on the boot partition,
# which the Raspberry Pi firmware passes to the kernel (boot.img is not used).
# ttyAMA10 is the Pi 5 debug UART (serial10 alias in bcm2712-rpi.dtsi).
BOARD_KERNEL_CMDLINE := console=tty0 console=ttyAMA10,115200 root=/dev/ram0 rootwait
BOARD_KERNEL_CMDLINE += androidboot.hardware=rpi5 androidboot.console=tty0
# PSI is built in but default-disabled (CONFIG_PSI_DEFAULT_DISABLED=y); lmkd requires it.
BOARD_KERNEL_CMDLINE += psi=1
# TEMP: permissive until the device sepolicy is complete.
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
ifneq ($(TARGET_BUILD_VARIANT),user)
# Debug builds: keep the console alive and log every initcall and /dev/kmsg write.
BOARD_KERNEL_CMDLINE += no_console_suspend initcall_debug printk.devkmsg=on
endif
BOARD_INCLUDE_RECOVERY_DTBO := false
BOARD_USES_GENERIC_KERNEL_IMAGE := false

# Kernel modules installed in /vendor/lib/modules (see modules.list in the
# kernel repo): the Wi-Fi and Bluetooth drivers, loaded by init.rpi5.rc.
BOARD_VENDOR_KERNEL_MODULES := $(wildcard kernel/rpi/rpi5/modules/*.ko)

# Filesystem & Partition Layout (Static Raw Partitions)
TARGET_USERIMAGES_USE_EXT4 := true
BOARD_FLASH_BLOCK_SIZE := 4096

# Output Directory Mapping
TARGET_COPY_OUT_VENDOR := vendor
TARGET_COPY_OUT_PRODUCT := system/product
TARGET_COPY_OUT_SYSTEM_EXT := system/system_ext

# Static partition sizes
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864          # 64MB
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 2147483648      # 2GB
BOARD_VENDORIMAGE_PARTITION_SIZE := 536870912       # 512MB
BOARD_USERDATAIMAGE_PARTITION_SIZE := 1073741824    # 1GB

# Filesystem types
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := ext4

# Wi-Fi: wpa_supplicant over nl80211 for brcmfmac. WPA_SUPPLICANT_VERSION makes
# external/wpa_supplicant_8 build its modules. There is no Wi-Fi vendor HAL; the
# framework drives wlan0 through wificond and the supplicant AIDL service.
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
# Install the supplicant's own init service (AIDL ISupplicant/default);
# the variable name is historical.
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true

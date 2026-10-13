$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

PRODUCT_NAME := rpi5
PRODUCT_DEVICE := rpi5
PRODUCT_BRAND := RaspberryPi
PRODUCT_MANUFACTURER := RaspberryPi
PRODUCT_MODEL := ZeeOS 15 on Raspberry Pi 5

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=180 \
    ro.surface_flinger.has_wide_color_display=false \
    ro.surface_flinger.has_HDR_display=false \
    ro.surface_flinger.use_color_management=false \
    ro.control_privapp_permissions=enforce

PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.usb.config=adb \
    service.adb.tcp.port=5555 \
    ro.adb.secure=0 \
    ro.debuggable=1

PRODUCT_COPY_FILES += \
    device/rpi/rpi5/fstab.rpi5:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.rpi5 \
    device/rpi/rpi5/init.rpi5.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.rpi5.rc \
    device/rpi/rpi5/input/qwerty.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/qwerty.idc \
    kernel/rpi/rpi5/Image.gz:kernel

DEVICE_MANIFEST_FILE += device/rpi/rpi5/vintf/manifest.xml

PRODUCT_PACKAGES += \
    gralloc.minigbm \
    hwcomposer.drm

# Health HAL (AIDL, AOSP reference implementation)
PRODUCT_PACKAGES += android.hardware.health-service.example

# Audio HAL (AIDL, AOSP reference implementation, vendor APEX)
PRODUCT_PACKAGES += com.android.hardware.audio
PRODUCT_COPY_FILES += \
    hardware/interfaces/audio/aidl/default/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects_config.xml

# Audio policy configuration (device main file + AOSP templates, read by the AIDL audio HAL)
PRODUCT_COPY_FILES += \
    device/rpi/rpi5/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/primary_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/primary_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration_7_0.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration_7_0.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/surround_sound_configuration_5_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/surround_sound_configuration_5_0.xml

# KeyMint HAL (AIDL, AOSP Rust nonsecure implementation, vendor APEX)
PRODUCT_PACKAGES += com.android.hardware.keymint.rust_nonsecure

# Gatekeeper HAL (AIDL, AOSP nonsecure implementation, vendor APEX)
PRODUCT_PACKAGES += com.android.hardware.gatekeeper.nonsecure

# Device feature set (AOSP tablet profile). Declares android.software.app_widgets,
# without which AppWidgetService is not started and Launcher3 crashes (NPE).
# TODO(originality): replace with an RPi5-specific feature list.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/tablet_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/tablet_core_hardware.xml

# Ethernet controller on RP1 (macb, eth0). ConnectivityService starts
# EthernetService only when this feature is declared (deviceSupportsEthernet()).
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.ethernet.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.ethernet.xml

# USB host ports (RP1 xHCI). SystemServer starts UsbService only when this
# feature (or usb.accessory) is declared; UsbService then creates UsbHostManager.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.usb.host.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.host.xml

# Dalvik/ART heap sizing for an ~8 GB device. Without it ART defaults to a 16 MiB
# growth limit and system_server/SystemUI die with OutOfMemoryError.
$(call inherit-product, frameworks/native/build/phone-xhdpi-6144-dalvik-heap.mk)

# Gagalkan build kalau PRODUCT_PACKAGES berisi module yang tidak ada
$(call enforce-product-packages-exist, \
    product_manifest.xml \
    android.hardware.health@2.0-impl-default.recovery \
    DeviceDiagnostics)

# Debug: persist logcat to /data/misc/logd (readable from host)
PRODUCT_SYSTEM_PROPERTIES += \
    persist.logd.logpersistd=logcatd

# Kernel has no ashmem driver (removed upstream). Let libcutils back ashmem
# regions with memfd (CONFIG_MEMFD_CREATE=y). Platform property -> system props.
PRODUCT_SYSTEM_PROPERTIES += \
    sys.use_memfd=true

# Graphics (Plan B): software rendering - ANGLE (GLES) on SwiftShader (Vulkan)

PRODUCT_PACKAGES += \
    libEGL_angle \
    libGLESv1_CM_angle \
    libGLESv2_angle \
    vulkan.pastel

PRODUCT_VENDOR_PROPERTIES += \
    ro.hardware.egl=angle \
    ro.hardware.vulkan=pastel \
    ro.opengles.version=196609

# Graphics: buffer allocator + mapper (minigbm, dumb buffers on vc4)
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator-service.minigbm \
    mapper.minigbm

# Graphics: composer HWC3 (drm_hwcomposer, AIDL composer3 V3). rc + VINTF dipasang oleh modulnya sendiri
PRODUCT_PACKAGES += \
    android.hardware.composer.hwc3-service.drm

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
    device/rpi/rpi5/android-sdcard.dtbo:boot/overlays/android-sdcard.dtbo \
    device/rpi/rpi5/fstab.rpi5:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.rpi5 \
    device/rpi/rpi5/init.rpi5.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.rpi5.rc \
    device/rpi/rpi5/input/qwerty.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/qwerty.idc \
    kernel/rpi/rpi5/Image.gz:kernel

DEVICE_MANIFEST_FILE += device/rpi/rpi5/vintf/manifest.xml

PRODUCT_PACKAGES += \
    gralloc.minigbm \
    hwcomposer.drm

$(call inherit-product-if-exists, vendor/rpi/rpi5/rpi5-vendor.mk)

# Health HAL (AIDL, AOSP reference implementation)
PRODUCT_PACKAGES += android.hardware.health-service.example

# Audio HAL (AIDL, AOSP reference implementation, vendor APEX)
PRODUCT_PACKAGES += com.android.hardware.audio

# Gagalkan build kalau PRODUCT_PACKAGES berisi module yang tidak ada
$(call enforce-product-packages-exist, \
    product_manifest.xml \
    android.hardware.health@2.0-impl-default.recovery \
    DeviceDiagnostics)

# Debug: persist logcat to /data/misc/logd (readable from host)
PRODUCT_SYSTEM_PROPERTIES += \
    persist.logd.logpersistd=logcatd

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

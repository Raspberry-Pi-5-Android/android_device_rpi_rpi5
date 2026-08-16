$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

PRODUCT_NAME := rpi5
PRODUCT_DEVICE := rpi5
PRODUCT_BRAND := RaspberryPi
PRODUCT_MANUFACTURER := RaspberryPi
PRODUCT_MODEL := AOSP 15 on Raspberry Pi 5

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
    device/rpi/rpi5/input/qwerty.idc:$(TARGET_COPY_OUT_VENDOR)/usr/idc/qwerty.idc

PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator-service.default \
    android.hardware.graphics.composer-service.default \
    gralloc.minigbm \
    hwcomposer.drm \
    libGLES_mesa \
    vulkan.broadcom

$(call inherit-product-if-exists, vendor/rpi/rpi5/rpi5-vendor.mk)
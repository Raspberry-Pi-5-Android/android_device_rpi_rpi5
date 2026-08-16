$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

PRODUCT_NAME := rpi5
PRODUCT_DEVICE := rpi5
PRODUCT_BRAND := RaspberryPi
PRODUCT_MANUFACTURER := RaspberryPi
PRODUCT_MODEL := AOSP 15 on Raspberry Pi 5

PRODUCT_PROPERTY_OVERRIDES += \
    ro.sf.lcd_density=180 \
    ro.control_privapp_permissions=enforce

PRODUCT_COPY_FILES += \
    device/rpi/rpi5/fstab.rpi5:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.rpi5

$(call inherit-product-if-exists, vendor/rpi/rpi5/rpi5-vendor.mk)
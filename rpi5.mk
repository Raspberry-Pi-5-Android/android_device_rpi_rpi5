# 64-bit only: no 32-bit zygote and no 32-bit libraries.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)

PRODUCT_NAME := rpi5
PRODUCT_DEVICE := rpi5
PRODUCT_BRAND := Android
PRODUCT_MANUFACTURER := Raspberry Pi
PRODUCT_MODEL := AOSP on Raspberry Pi 5

PRODUCT_VENDOR_PROPERTIES += \
    ro.sf.lcd_density=160 \
    ro.surface_flinger.has_wide_color_display=false \
    ro.surface_flinger.has_HDR_display=false \
    ro.surface_flinger.use_color_management=false \
    ro.control_privapp_permissions=enforce

# adb over TCP for development builds (Ethernet; no USB gadget yet).
# ro.debuggable, ro.adb.secure and persist.sys.usb.config are already set
# per variant by the build system (sysprop_config.mk, post_process_props.py).
ifneq ($(TARGET_BUILD_VARIANT),user)
PRODUCT_VENDOR_PROPERTIES += \
    service.adb.tcp.port=5555
endif

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
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/surround_sound_configuration_5_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/surround_sound_configuration_5_0.xml

# KeyMint HAL (AIDL, AOSP Rust nonsecure implementation, vendor APEX)
PRODUCT_PACKAGES += com.android.hardware.keymint.rust_nonsecure

# Gatekeeper HAL (AIDL, AOSP nonsecure implementation, vendor APEX)
PRODUCT_PACKAGES += com.android.hardware.gatekeeper.nonsecure

# Device feature set: own list derived from the AOSP tablet profile, without
# hardware the board does not have (location, sensors, touchscreen,
# microphone, portrait). app_widgets is required for AppWidgetService
# (Launcher3). faketouch: pointer input from a mouse.
PRODUCT_COPY_FILES += \
    device/rpi/rpi5/permissions/rpi5_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/rpi5_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.faketouch.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.faketouch.xml

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

# Fail the build if PRODUCT_PACKAGES names a module that does not exist
# (the modules listed below are exempt).
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

# Graphics: OpenGL ES and Vulkan run on the GPU through Mesa (ro.hardware.egl=mesa,
# ro.hardware.vulkan=broadcom). ANGLE and SwiftShader (pastel) stay installed as
# fallbacks.

PRODUCT_PACKAGES += \
    libEGL_angle \
    libGLESv1_CM_angle \
    libGLESv2_angle \
    vulkan.pastel

PRODUCT_VENDOR_PROPERTIES += \
    ro.hardware.egl=mesa \
    ro.hardware.vulkan=broadcom \
    ro.opengles.version=196609

# Mesa GPU drivers (vendor/rpi/rpi5/mesa): V3D/VC4 for OpenGL ES, V3DV for Vulkan.
# They are selected by ro.hardware.egl=mesa and ro.hardware.vulkan=broadcom above.
PRODUCT_PACKAGES += \
    libEGL_mesa \
    libGLESv1_CM_mesa \
    libGLESv2_mesa \
    libgallium_dri \
    vulkan.broadcom

# Vulkan features as measured on V3DV (API 1.3, compute queue). Level 1 and a
# dEQP level are not claimed because they have not been verified.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_3.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml

# Graphics: buffer allocator + mapper (minigbm, dumb buffers on vc4)
PRODUCT_PACKAGES += \
    android.hardware.graphics.allocator-service.minigbm \
    mapper.minigbm

# Graphics: composer HWC3 (drm_hwcomposer, AIDL composer3 V3). The module installs
# its own init rc and VINTF fragment.
PRODUCT_PACKAGES += \
    android.hardware.composer.hwc3-service.drm

# Display: keep the HDMI display landscape; portrait apps are letterboxed.
PRODUCT_COPY_FILES += \
    device/rpi/rpi5/display_settings.xml:$(TARGET_COPY_OUT_VENDOR)/etc/display_settings.xml

# Power HAL: CPU boost on interaction and app launch.
PRODUCT_PACKAGES += \
    android.hardware.power-service.rpi5

# Graphics buffers: let Mesa load the minigbm gralloc0 module (CrOS API) so it
# gets buffer modifiers and plane layouts instead of using its fallback path.
PRODUCT_VENDOR_PROPERTIES += \
    ro.hardware.gralloc=minigbm

# Wi-Fi and Bluetooth firmware for the CYW43455 (vendor/rpi/rpi5/firmware),
# installed in /vendor/firmware/brcm. The drivers are kernel modules loaded by
# init.rpi5.rc. Each feature is declared next to the HAL that provides it.
PRODUCT_PACKAGES += \
    rpi5_brcmfmac43455-sdio.bin \
    rpi5_brcmfmac43455-sdio.clm_blob \
    rpi5_brcmfmac43455-sdio.txt \
    rpi5_BCM4345C0.hcd

# Bluetooth: AOSP HCI HAL on hci0 (hci_uart + btbcm, loaded by init.rpi5.rc)
# through the HCI user channel. /dev/rfkill stays root-only on purpose: the HAL
# soft-blocks Bluetooth through it before binding the user channel, and the
# kernel refuses to open an rfkill-blocked controller (ERFKILL).
PRODUCT_PACKAGES += android.hardware.bluetooth-service.default

# Bluetooth profiles that are tested on this device. The stack disables
# profiles whose property is unset, except GATT, which is on by default.
PRODUCT_VENDOR_PROPERTIES += \
    bluetooth.profile.a2dp.source.enabled=true \
    bluetooth.profile.avrcp.target.enabled=true

# Bluetooth features: the CYW43455 supports BR/EDR and LE.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.bluetooth.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth.xml \
    frameworks/native/data/etc/android.hardware.bluetooth_le.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.bluetooth_le.xml

# Media: the software Codec2 service (media.swcodec) registers only the AIDL
# store, and the framework client picks HIDL unless this is set.
PRODUCT_VENDOR_PROPERTIES += media.c2.hal.selection=aidl

# mediaextractor seccomp additions for memfd-backed shared memory.
PRODUCT_COPY_FILES += \
    device/rpi/rpi5/seccomp_policy/mediaextractor.policy:$(TARGET_COPY_OUT_VENDOR)/etc/seccomp_policy/mediaextractor.policy

# Wi-Fi: wpa_supplicant (AIDL service, started by the framework) with the AOSP
# configuration template, which it copies to /data/vendor/wifi/wpa on first use.
PRODUCT_PACKAGES += wpa_supplicant
PRODUCT_COPY_FILES += \
    external/wpa_supplicant_8/wpa_supplicant/wpa_supplicant_template.conf:$(TARGET_COPY_OUT_VENDOR)/etc/wifi/wpa_supplicant.conf

# Wi-Fi feature (station mode). Wi-Fi Direct, Passpoint and hotspot are not
# declared until they are tested.
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.wifi.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.wifi.xml

# Framework resource overlay (overlays/core): software navigation bar.
PRODUCT_PACKAGES += rpi5_overlay_frameworks_base_core

# Boot partition (p1) image for the Raspberry Pi firmware.
#
# The Pi 5 EEPROM firmware reads config.txt and cmdline.txt from a FAT
# partition and loads the kernel, initramfs, device trees and overlays
# from it; boot.img is not used. rpiboot.img is that partition (FAT32,
# label "boot") and is written as-is to p1 of the SD card.

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),rpi5)

RPI_DEVICE_DIR := $(LOCAL_PATH)
RPI_KERNEL_DIR := kernel/rpi/rpi5
RPI_BOOT_CONFIG := vendor/rpi/rpi5/boot/config.txt
# Same size and geometry as the boot partition on the SD card (128 MiB,
# 512-byte sectors, starting at sector 2048). The geometry is passed
# explicitly because newfs_msdos cannot query it from a regular file.
RPI_BOOT_IMAGE_SIZE := 134217728
RPI_BOOT_IMAGE_SECTORS := 262144

INSTALLED_RPIBOOTIMAGE_TARGET := $(PRODUCT_OUT)/rpiboot.img
RPI_BOOT_STAGING := $(PRODUCT_OUT)/rpiboot

# All BCM2712 board DTBs are shipped: the firmware picks one by board revision.
RPI_BOOT_DTBS := $(sort $(wildcard $(RPI_KERNEL_DIR)/bcm2712*.dtb))
RPI_BOOT_OVERLAYS := $(sort $(wildcard $(RPI_KERNEL_DIR)/overlays/*))

RPI_BOOT_DEPS := $(RPI_KERNEL_DIR)/Image.gz
RPI_BOOT_DEPS += $(PRODUCT_OUT)/ramdisk.img
RPI_BOOT_DEPS += $(RPI_BOOT_DTBS) $(RPI_BOOT_OVERLAYS)
RPI_BOOT_DEPS += $(RPI_DEVICE_DIR)/android-sdcard.dtbo
RPI_BOOT_DEPS += $(RPI_BOOT_CONFIG)
# cmdline.txt is generated from BOARD_KERNEL_CMDLINE.
RPI_BOOT_DEPS += $(RPI_DEVICE_DIR)/BoardConfig.mk
RPI_BOOT_DEPS += $(HOST_OUT_EXECUTABLES)/newfs_msdos $(HOST_OUT_EXECUTABLES)/mcopy

$(INSTALLED_RPIBOOTIMAGE_TARGET): PRIVATE_CMDLINE := $(strip $(BOARD_KERNEL_CMDLINE))
$(INSTALLED_RPIBOOTIMAGE_TARGET): PRIVATE_STAGING := $(RPI_BOOT_STAGING)
$(INSTALLED_RPIBOOTIMAGE_TARGET): PRIVATE_DTBS := $(RPI_BOOT_DTBS)
$(INSTALLED_RPIBOOTIMAGE_TARGET): PRIVATE_OVERLAYS := $(RPI_BOOT_OVERLAYS)
$(INSTALLED_RPIBOOTIMAGE_TARGET): PRIVATE_DEVICE_DIR := $(RPI_DEVICE_DIR)
$(INSTALLED_RPIBOOTIMAGE_TARGET): $(RPI_BOOT_DEPS)
	$(hide) rm -rf $(PRIVATE_STAGING) $@
	$(hide) mkdir -p $(PRIVATE_STAGING)/overlays
	$(hide) cp $(RPI_KERNEL_DIR)/Image.gz $(PRIVATE_STAGING)/kernel8.img
	$(hide) cp $(PRODUCT_OUT)/ramdisk.img $(PRIVATE_STAGING)/ramdisk.img
	$(hide) cp $(PRIVATE_DTBS) $(PRIVATE_STAGING)/
	$(hide) cp $(PRIVATE_OVERLAYS) $(PRIVATE_STAGING)/overlays/
	$(hide) cp $(PRIVATE_DEVICE_DIR)/android-sdcard.dtbo $(PRIVATE_STAGING)/overlays/
	$(hide) cp $(RPI_BOOT_CONFIG) $(PRIVATE_STAGING)/config.txt
	$(hide) echo '$(PRIVATE_CMDLINE)' > $(PRIVATE_STAGING)/cmdline.txt
	$(hide) $(HOST_OUT_EXECUTABLES)/newfs_msdos -F 32 -c 1 -L boot -S 512 -s $(RPI_BOOT_IMAGE_SECTORS) -h 255 -u 63 -o 2048 -C $(RPI_BOOT_IMAGE_SIZE) $@ >/dev/null
	$(hide) MTOOLS_SKIP_CHECK=1 $(HOST_OUT_EXECUTABLES)/mcopy -s -Q -i $@ $(PRIVATE_STAGING)/* ::/
	@echo "Boot partition image: $@"

.PHONY: rpibootimage
rpibootimage: $(INSTALLED_RPIBOOTIMAGE_TARGET)

droidcore: $(INSTALLED_RPIBOOTIMAGE_TARGET)

endif

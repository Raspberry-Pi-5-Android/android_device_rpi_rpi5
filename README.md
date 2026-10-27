# android_device_rpi_rpi5

Device configuration for AOSP Android on the Raspberry Pi 5.
Branch `android-15`: Android 15, product `rpi5`, 64-bit only.

## Contents

| Path | Purpose |
|---|---|
| `BoardConfig.mk`, `rpi5.mk`, `AndroidProducts.mk` | Board and product configuration |
| `init.rpi5.rc`, `fstab.rpi5` | Init script and mount table |
| `Android.mk` | Boot partition image target (`rpibootimage`) |
| `display_settings.xml` | Display settings |
| `input/` | Input device configuration |
| `permissions/` | Device feature list |
| `overlays/` | Framework resource overlay |
| `vintf/` | VINTF manifest |
| `power/` | Power HAL |
| `audio/` | Audio policy configuration |
| `seccomp_policy/` | Seccomp additions for media processes |
| `sepolicy/` | Device SELinux policy |

Build instructions are in
[`android_local_manifest`](https://github.com/Raspberry-Pi-5-Android/android_local_manifest).

## License

Apache 2.0, unless a file states otherwise.

#!/system/bin/sh
# Lancelot Performance Booster - Customization Script (KernelSU)
# Runs during module installation

ui_print ""
ui_print "========================================"
ui_print "   Lancelot Performance Booster v2.0    "
ui_print "   For Redmi 9 (lancelot) - KernelSU   "
ui_print "========================================"
ui_print ""

# Check device
DEVICE=$(getprop ro.product.device)
if [ "$DEVICE" != "lancelot" ] && [ "$DEVICE" != "Lava" ] && [ "$DEVICE" != "lava" ]; then
    ui_print "! Warning: This module is designed for Redmi 9 (lancelot)"
    ui_print "! Detected device: $DEVICE"
    ui_print "! Proceeding anyway..."
    ui_print ""
fi

# Check KernelSU
KSU_VER=0
if command -v ksud >/dev/null 2>&1; then
    KSU_VER=$(ksud --version 2>/dev/null | head -1)
    ui_print "- KernelSU detected: $KSU_VER"
else
    ui_print "! WARNING: ksud not found!"
    ui_print "! This module requires KernelSU to function."
    ui_print "! Aborting installation."
    ui_print ""
    abort "! Not a KernelSU environment"
fi

# Check kernel
KVER=$(uname -r)
ui_print "- Kernel: $KVER"
ui_print ""

# Check Vulkan support
HAS_VULKAN=$(getprop ro.hardware.vulkan)
if [ -n "$HAS_VULKAN" ]; then
    ui_print "- Vulkan support: $HAS_VULKAN"
else
    ui_print "! Warning: Vulkan not detected in device properties"
    ui_print "! Vulkan renderer may not work on this device"
    ui_print ""
fi

# Set permissions
ui_print "- Setting permissions..."
set_perm_recursive $MODPATH 0 0 0755 0644
set_perm $MODPATH/service.sh 0 0 0755
set_perm $MODPATH/post-fs-data.sh 0 0 0755
set_perm $MODPATH/boot-completed.sh 0 0 0755
set_perm $MODPATH/backup.sh 0 0 0755

# Create log directory
mkdir -p /data/adb/lancelot-perf
chmod 0755 /data/adb/lancelot-perf

ui_print ""
ui_print "- Installation complete!"
ui_print ""
ui_print "  Tweaks applied:"
ui_print "  - VFS cache pressure = 10"
ui_print "  - Vulkan renderer (skiavk)"
ui_print "  - Touch sampling rate boosted"
ui_print "  - Memory + scheduler + I/O optimized"
ui_print "  - GPU performance governor"
ui_print "  - Network TCP BBR"
ui_print ""
ui_print "- Reboot required to apply changes"
ui_print ""
ui_print "========================================"
ui_print "   Reboot your device to activate      "
ui_print "========================================"

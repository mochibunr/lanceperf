#!/system/bin/sh
# Lancelot Performance Booster - Early Boot Script (KernelSU)
# Runs in post-fs-data mode (blocking, before modules mount)

MODDIR=${0%/*}
BACKUP_DIR=/data/adb/lancelot-perf
FLAG_FILE=$BACKUP_DIR/.backup_done

mkdir -p "$BACKUP_DIR"

# ============================================
# BACKUP ORIGINAL VALUES (first boot only)
# ============================================
if [ ! -f "$FLAG_FILE" ]; then
    sh $MODDIR/backup.sh
fi

# ============================================
# APPLY TWEAKS
# ============================================

# VFS cache pressure - aggressive caching
write /proc/sys/vm/vfs_cache_pressure 10

# Min free memory
write /proc/sys/vm/min_free_kbytes 16384

# Reduce page reclaim aggressiveness
write /proc/sys/vm/watermark_boost_factor 0
write /proc/sys/vm/watermark_scale_factor 100

# Entropy pool
write /proc/sys/kernel/random/read_wakeup_threshold 64
write /proc/sys/kernel/random/write_wakeup_threshold 128

# Kernel tweaks
write /proc/sys/kernel/printk "0 0 0 0"
write /proc/sys/kernel/watchdog 0
write /proc/sys/vm/max_map_count 262144
write /proc/sys/kernel/shmmax 67108864
write /proc/sys/kernel/shmall 2097152

# Touch - early init for game mode
for touch_path in \
    /sys/devices/virtual/touch/touch_dev \
    /sys/devices/virtual/touch/touchscreen \
    /sys/class/touch/touch_dev
do
    if [ -d "$touch_path" ]; then
        write "$touch_path/touch_mode" 1
        write "$touch_path/bump_sample_rate" 1
        write "$touch_path/Touch_Report_Rate" 1
    fi
done

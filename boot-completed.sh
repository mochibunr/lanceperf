#!/system/bin/sh
# Lancelot Performance Booster - Boot Completed Script (KernelSU)
# Runs after boot is fully complete

MODDIR=${0%/*}
LOGFILE=/data/adb/lancelot-perf/perf.log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [boot-completed] $1" >> $LOGFILE
}

log "Boot completed stage starting"

# Re-apply VFS cache pressure
write /proc/sys/vm/vfs_cache_pressure 10

# Re-apply I/O scheduler
for queue in /sys/block/*/queue
do
    devname=$(basename $(dirname "$queue"))
    case "$devname" in
        ram*|loop*|dm*) continue ;;
    esac
    if [ -f "$queue/scheduler" ]; then
        if grep -q "bfq" "$queue/scheduler" 2>/dev/null; then
            write "$queue/scheduler" "bfq"
        fi
    fi
    write "$queue/read_ahead_kb" 256
    write "$queue/nr_requests" 64
done

# Re-apply touch high sample rate
for touch_path in \
    /sys/devices/virtual/touch/touch_dev \
    /sys/devices/virtual/touch/touchscreen \
    /sys/class/touch/touch_dev
do
    if [ -d "$touch_path" ]; then
        write "$touch_path/touch_mode" 1
        write "$touch_path/bump_sample_rate" 1
        write "$touch_path/Touch_Report_Rate" 1
        write "$touch_path/Touch_Active_MODE" 1
        write "$touch_path/Touch_Edge_Filter" 0
        write "$touch_path/Touch_UP_THRESHOLD" 0
        log "Touch re-tuned at $touch_path"
    fi
done

# Boost top-app one more time
if [ -d "/dev/stune/top-app" ]; then
    write /dev/stune/top-app/schedtune.prefer_idle 1
    write /dev/stune/top-app/schedtune.boost 1
fi

# Drop caches to start fresh
write /proc/sys/vm/drop_caches 3
sync

log "Boot completed optimizations applied"

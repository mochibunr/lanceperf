#!/system/bin/sh
# Lancelot Performance Booster - Boot Script (KernelSU)
# Runs in late_start service mode (non-blocking)

MODDIR=${0%/*}
LOGFILE=/data/adb/lancelot-perf/perf.log

mkdir -p /data/adb/lancelot-perf

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOGFILE
}

log "=== Lancelot Perf Booster starting ==="

# Log backup status
if [ -f "/data/adb/lancelot-perf/.backup_done" ]; then
    log "Original values backed up - restore available on uninstall"
else
    log "Backup pending - will run on next post-fs-data"
fi

# ============================================
# VFS CACHE PRESSURE
# ============================================
write /proc/sys/vm/vfs_cache_pressure 10
log "vfs_cache_pressure set to 10"

# ============================================
# MEMORY MANAGEMENT
# ============================================
write /proc/sys/vm/swappiness 30
write /proc/sys/vm/dirty_ratio 30
write /proc/sys/vm/dirty_background_ratio 5
write /proc/sys/vm/dirty_expire_centisecs 3000
write /proc/sys/vm/dirty_writeback_centisecs 500
write /proc/sys/vm/min_free_kbytes 16384
write /proc/sys/vm/extra_free_kbytes 8192
write /proc/sys/vm/overcommit_memory 0
write /proc/sys/vm/overcommit_ratio 80
write /proc/sys/vm/zone_reclaim_mode 0
write /proc/sys/vm/page-cluster 0
write /proc/sys/vm/compact_unevictable_allowed 1
write /proc/sys/vm/extfrag_threshold 50
write /proc/sys/vm/watermark_boost_factor 0
write /proc/sys/vm/watermark_scale_factor 100

log "Memory parameters applied"

# ============================================
# SCHEDULER TWEAKS (CFS)
# ============================================
write /proc/sys/kernel/sched_migration_cost_ns 5000000
write /proc/sys/kernel/sched_min_task_util_for_colocation 0
write /proc/sys/kernel/sched_latency_ns 4000000
write /proc/sys/kernel/sched_min_granularity_ns 500000
write /proc/sys/kernel/sched_wakeup_granularity_ns 1000000
write /proc/sys/kernel/sched_rt_runtime_us 950000
write /proc/sys/kernel/sched_rt_period_us 1000000

# SchedTune boost for top-app
if [ -d "/dev/stune/top-app" ]; then
    write /dev/stune/top-app/schedtune.prefer_idle 1
    write /dev/stune/top-app/schedtune.boost 1
fi
if [ -d "/dev/stune/foreground" ]; then
    write /dev/stune/foreground/schedtune.prefer_idle 0
    write /dev/stune/foreground/schedtune.boost 0
fi
if [ -d "/dev/stune/background" ]; then
    write /dev/stune/background/schedtune.prefer_idle 0
    write /dev/stune/background/schedtune.boost 0
fi

log "Scheduler parameters applied"

# ============================================
# CPUFREQ / SCHEDUTIL TWEAKS
# ============================================
find /sys/devices/system/cpu/ -name schedutil -type d 2>/dev/null | while IFS= read -r governor
do
    write "$governor/up_rate_limit_us" 0
    write "$governor/down_rate_limit_us" 5000
    write "$governor/rate_limit_us" 0
    write "$governor/hispeed_load" 85
done

for cpu_input_boost in /sys/devices/system/cpu/cpu*/cpufreq/cpu_input_boost
do
    [ -f "$cpu_input_boost" ] && write "$cpu_input_boost" 1
done

for iowait_boost in /sys/devices/system/cpu/cpu*/cpufreq/iowait_boost_enable
do
    [ -f "$iowait_boost" ] && write "$iowait_boost" 1
done

log "CPU frequency parameters applied"

# ============================================
# I/O SCHEDULER TWEAKS
# ============================================
for queue in /sys/block/*/queue
do
    write "$queue/read_ahead_kb" 256
    write "$queue/nr_requests" 64
    write "$queue/add_random" 1
    write "$queue/nomerges" 0
    write "$queue/rq_affinity" 2
    write "$queue/io_poll_delay" 0
    write "$queue/rotational" 0
    write "$queue/iostats" 0

    devname=$(basename $(dirname "$queue"))
    case "$devname" in
        ram*|loop*|dm*) continue ;;
    esac

    if [ -f "$queue/scheduler" ]; then
        if grep -q "bfq" "$queue/scheduler" 2>/dev/null; then
            write "$queue/scheduler" "bfq"
        elif grep -q "none" "$queue/scheduler" 2>/dev/null; then
            write "$queue/scheduler" "none"
        elif grep -q "mq-deadline" "$queue/scheduler" 2>/dev/null; then
            write "$queue/scheduler" "mq-deadline"
        fi
    fi

    if [ -f "$queue/iosched/low_latency" ]; then
        write "$queue/iosched/low_latency" 1
    fi
done

log "I/O parameters applied"

# ============================================
# TOUCH SAMPLING RATE (Xiaomi/MTK)
# ============================================

# --- Xiaomi Touch Driver nodes ---
# Game mode + high report rate
for touch_path in \
    /sys/devices/virtual/touch/touch_dev \
    /sys/devices/virtual/touch/touchscreen \
    /sys/class/touch/touch_dev \
    /sys/class/touch/touchscreen
do
    if [ -d "$touch_path" ]; then
        # Enable game mode
        write "$touch_path/touch_mode" 1
        # Set report rate to max (1 = high sample rate)
        write "$touch_path/bump_sample_rate" 1
        # Touch active mode
        write "$touch_path/Touch_Active_MODE" 1
        # Reduce edge filter for faster response
        write "$touch_path/Touch_Edge_Filter" 0
        # Reduce UP_THRESHOLD for faster touch response
        write "$touch_path/Touch_UP_THRESHOLD" 0
        # Reduce tolerance for precision
        write "$touch_path/Touch_Tolerance" 0
        # Max weight
        write "$touch_path/Touch_Wgh_Max" 100
        write "$touch_path/Touch_Wgh_Min" 0
        write "$touch_path/Touch_Wgh_Step" 1
        # Touch report rate mode 9 = high
        write "$touch_path/Touch_Report_Rate" 1
        log "Xiaomi touch node found at $touch_path - tuned"
    fi
done

# --- MediaTek Touch Driver nodes ---
for touch_path in \
    /sys/devices/platform/11012000 TOUCH/touch \
    /sys/devices/platform/11012000 TOUCH/touchscreen \
    /sys/devices/virtual/input/touchscreen \
    /sys/devices/platform/mtk-tpd/touch \
    /sys/devices/platform/mtk_tpd/touch
do
    if [ -d "$touch_path" ]; then
        # Set high report rate
        write "$touch_path/report_rate" 240 2>/dev/null
        write "$touch_path/touch_report_rate" 240 2>/dev/null
        write "$touch_path/sample_rate" 240 2>/dev/null
        log "MediaTek touch node found at $touch_path - tuned"
    fi
done

# --- Generic input device tuning ---
# Increase touch device repeat rate and reduce debounce
for input_dir in /sys/class/input/event*/device
do
    if [ -d "$input_dir" ]; then
        # Reduce repeat delay for faster repeated inputs
        write "$input_dir/repeat_delay" 150 2>/dev/null
    fi
done

# --- Touchscreen sensitivity via input subsystem ---
for ts_dir in /sys/class/input/event*
do
    devname=$(cat "$ts_dir/device/name" 2>/dev/null)
    case "$devname" in
        *touch*|*Touch*|*TP*|*tp*|*sec_touch*|*goodix*|*fts*|*novatek*)
            # Reduce debounce for faster touch registration
            write "$ts_dir/device/debounce" 0 2>/dev/null
            # Reduce filtering delay
            write "$ts_dir/device/filter" 0 2>/dev/null
            log "Input device: $devname - touch optimized"
            ;;
    esac
done

log "Touch sampling rate applied"

# ============================================
# NETWORK TWEAKS
# ============================================
if grep -q "bbr" /proc/sys/net/ipv4/tcp_available_congestion_control 2>/dev/null; then
    write /proc/sys/net/ipv4/tcp_congestion_control "bbr"
    write /proc/sys/net/core/default_qdisc "fq"
fi

write /proc/sys/net/core/rmem_max 16777216
write /proc/sys/net/core/wmem_max 16777216
write /proc/sys/net/core/rmem_default 1048576
write /proc/sys/net/core/wmem_default 1048576
write /proc/sys/net/ipv4/tcp_rmem "4096 1048576 16777216"
write /proc/sys/net/ipv4/tcp_wmem "4096 1048576 16777216"
write /proc/sys/net/ipv4/tcp_fastopen 3
write /proc/sys/net/ipv4/tcp_slow_start_after_idle 0
write /proc/sys/net/ipv4/tcp_mtu_probing 1
write /proc/sys/net/ipv4/tcp_window_scaling 1
write /proc/sys/net/ipv4/tcp_timestamps 1
write /proc/sys/net/ipv4/tcp_sack 1
write /proc/sys/net/ipv4/tcp_no_metrics_save 1
write /proc/sys/net/ipv4/tcp_syncookies 1
write /proc/sys/net/ipv4/tcp_tw_reuse 1
write /proc/sys/net/ipv4/tcp_fin_timeout 15
write /proc/sys/net/ipv4/tcp_keepalive_time 600
write /proc/sys/net/ipv4/tcp_keepalive_intvl 30
write /proc/sys/net/ipv4/tcp_keepalive_probes 5
write /proc/sys/net/ipv4/ip_local_port_range "1024 65535"
write /proc/sys/net/ipv4/udp_rmem_min 8192
write /proc/sys/net/ipv4/udp_wmem_min 8192

log "Network parameters applied"

# ============================================
# MGLRU (if available)
# ============================================
if [ -d "/sys/kernel/mm/lru_gen" ]; then
    write /sys/kernel/mm/lru_gen/enabled "y"
    write /sys/kernel/mm/lru_gen/min_ttl_ms 1000
    log "MGLRU enabled"
fi

# ============================================
# GPU TWEAKS (Mali-G52 MC2 - Helio G80)
# ============================================

# MediaTek GPU devfreq paths
for gpu_path in \
    /sys/class/devfreq/13000000.mali \
    /sys/class/devfreq/mtk-devfreq-mali \
    /sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali
do
    if [ -d "$gpu_path" ]; then
        # Set performance governor
        write "$gpu_path/governor" "performance" 2>/dev/null

        # If performance governor not available, tune adaptive
        if [ ! -f "$gpu_path/governor" ] || ! grep -q "performance" "$gpu_path/governor" 2>/dev/null; then
            write "$gpu_path/governor" "adaptive" 2>/dev/null
            write "$gpu_path/up_threshold" 90 2>/dev/null
            write "$gpu_path/down_threshold" 40 2>/dev/null
        fi

        # Set max frequency (Mali-G52 on G80 can go to ~950MHz)
        write "$gpu_path/max_freq" 950000000 2>/dev/null
        write "$gpu_path/min_freq" 200000000 2>/dev/null

        log "GPU parameters applied at $gpu_path"
    fi
done

# Mali-specific tweaks
for mali_path in /sys/devices/platform/soc/*/mali
do
    if [ -d "$mali_path" ]; then
        write "$mali_path/utilization_period" 16 2>/dev/null
        log "Mali GPU tuned at $mali_path"
    fi
done

log "GPU parameters applied"

# ============================================
# SYSTEM PROPERTIES (Vulkan + Performance)
# ============================================

# --- Vulkan Renderer ---
resetprop -n debug.hwui.renderer skiavk
resetprop -n ro.hwui.use_vulkan true
resetprop -n debug.hwui.use_vulkan true

# --- HWUI / Rendering ---
resetprop -n debug.renderengine.backend skiavk
resetprop -n debug.renderengine.skipshadercache true
resetprop -n debug.hwui.render_dirty_regions true
resetprop -n debug.hwui.skip_damage_region true
resetprop -n debug.hwui.profile false
resetprop -n debug.hwui.show_dirty_regions false
resetprop -n debug.hwui.show_overdraw counter
resetprop -n ro.surface_flinger.max_frame_buffer_acquired_buffers 2
resetprop -n debug.sf.latch_unsignaled 1
resetprop -n debug.sf.enable_hwc_vds 0

# --- ART/Dalvik (4-core dex2oat for Helio G80) ---
resetprop -n dalvik.vm.dex2oat-threads 4
resetprop -n dalvik.vm.image-dex2oat-threads 4
resetprop -n dalvik.vm.dex2oat-filter speed
resetprop -n dalvik.vm.heapgrowthlimit 256m
resetprop -n dalvik.vm.heapsize 512m
resetprop -n dalvik.vm.heapmaxfree 8m
resetprop -n dalvik.vm.heapminfree 1m
resetprop -n dalvik.vm.heaptargetutilization 0.75
resetprop -n dalvik.vm.dex2oat-swap false

# --- Logging ---
resetprop -n log.tag.stats_log OFF
resetprop -n persist.sys.privapp_debug false
resetprop -n persist.log.tag.stats_log OFF

# --- Process Management ---
resetprop -n ro.sys.fw.bg_apps_limit 32
resetprop -n ro.config.max_bg_processes 6

# --- ZRAM ---
resetprop -n ro.lmk.zram_enabled true

# --- Touch properties ---
resetprop -n ro.vendor.inputdevices.use_xiaomi_touch 1
resetprop -n persist.vendor.touch.game.mode 1
resetprop -n persist.vendor.touch.high.sample.rate 1

log "System properties applied (Vulkan + touch)"

# ============================================
# FINAL CLEANUP
# ============================================
sync

log "=== Lancelot Perf Booster complete ==="

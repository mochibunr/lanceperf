#!/system/bin/sh
# Lancelot Performance Booster - Backup Script
# Saves original system values before applying tweaks
# Called once on first boot after install

BACKUP_DIR=/data/adb/lancelot-perf
BACKUP_FILE=$BACKUP_DIR/backup.sh
FLAG_FILE=$BACKUP_DIR/.backup_done

# Only backup once
if [ -f "$FLAG_FILE" ]; then
    exit 0
fi

mkdir -p "$BACKUP_DIR"

echo "#!/system/bin/sh" > "$BACKUP_FILE"
echo "# Auto-generated backup of original system values" >> "$BACKUP_FILE"
echo "# Generated: $(date '+%Y-%m-%d %H:%M:%S')" >> "$BACKUP_FILE"
echo "" >> "$BACKUP_FILE"

# ============================================
# Backup VM sysctls
# ============================================
echo "# === VM VALUES ===" >> "$BACKUP_FILE"
for param in \
    vfs_cache_pressure swappiness dirty_ratio dirty_background_ratio \
    dirty_expire_centisecs dirty_writeback_centisecs min_free_kbytes \
    extra_free_kbytes overcommit_memory overcommit_ratio zone_reclaim_mode \
    page-cluster compact_unevictable_allowed extfrag_threshold \
    watermark_boost_factor watermark_scale_factor max_map_count
do
    val=$(cat /proc/sys/vm/$param 2>/dev/null)
    if [ -n "$val" ]; then
        echo "write /proc/sys/vm/$param $val" >> "$BACKUP_FILE"
    fi
done

# ============================================
# Backup Kernel sysctls
# ============================================
echo "" >> "$BACKUP_FILE"
echo "# === KERNEL VALUES ===" >> "$BACKUP_FILE"
for param in \
    sched_migration_cost_ns sched_min_task_util_for_colocation \
    sched_latency_ns sched_min_granularity_ns sched_wakeup_granularity_ns \
    sched_rt_runtime_us sched_rt_period_us \
    random/read_wakeup_threshold random/write_wakeup_threshold \
    printk watchdog shmmax shmall
do
    val=$(cat /proc/sys/kernel/$param 2>/dev/null)
    if [ -n "$val" ]; then
        echo "write /proc/sys/kernel/$param $val" >> "$BACKUP_FILE"
    fi
done

# ============================================
# Backup Network sysctls
# ============================================
echo "" >> "$BACKUP_FILE"
echo "# === NETWORK VALUES ===" >> "$BACKUP_FILE"

# Core
for param in rmem_max wmem_max rmem_default wmem_default default_qdisc; do
    val=$(cat /proc/sys/net/core/$param 2>/dev/null)
    if [ -n "$val" ]; then
        echo "write /proc/sys/net/core/$param $val" >> "$BACKUP_FILE"
    fi
done

# IPv4
for param in \
    tcp_congestion_control tcp_fastopen tcp_slow_start_after_idle \
    tcp_mtu_probing tcp_window_scaling tcp_timestamps tcp_sack \
    tcp_no_metrics_save tcp_syncookies tcp_tw_reuse tcp_fin_timeout \
    tcp_keepalive_time tcp_keepalive_intvl tcp_keepalive_probes \
    ip_local_port_range udp_rmem_min udp_wmem_min; do
    val=$(cat /proc/sys/net/ipv4/$param 2>/dev/null)
    if [ -n "$val" ]; then
        echo "write /proc/sys/net/ipv4/$param $val" >> "$BACKUP_FILE"
    fi
done

# TCP rmem/wmem (3 values: min default max)
for param in tcp_rmem tcp_wmem; do
    val=$(cat /proc/sys/net/ipv4/$param 2>/dev/null)
    if [ -n "$val" ]; then
        echo "write /proc/sys/net/ipv4/$param \"$val\"" >> "$BACKUP_FILE"
    fi
done

# ============================================
# Backup I/O scheduler settings
# ============================================
echo "" >> "$BACKUP_FILE"
echo "# === I/O VALUES ===" >> "$BACKUP_FILE"
for queue in /sys/block/*/queue; do
    devname=$(basename $(dirname "$queue"))
    case "$devname" in
        ram*|loop*|dm*) continue ;;
    esac

    for param in read_ahead_kb nr_requests add_random nomerges rq_affinity rotational iostats; do
        val=$(cat "$queue/$param" 2>/dev/null)
        if [ -n "$val" ]; then
            echo "write $queue/$param $val" >> "$BACKUP_FILE"
        fi
    done

    # Backup scheduler
    if [ -f "$queue/scheduler" ]; then
        sched=$(cat "$queue/scheduler" 2>/dev/null)
        echo "write $queue/scheduler \"$sched\"" >> "$BACKUP_FILE"
    fi
done

# ============================================
# Backup SchedTune values
# ============================================
echo "" >> "$BACKUP_FILE"
echo "# === SCHEDTUNE VALUES ===" >> "$BACKUP_FILE"
for stune_group in top-app foreground background; do
    if [ -d "/dev/stune/$stune_group" ]; then
        for param in schedtune.prefer_idle schedtune.boost; do
            val=$(cat "/dev/stune/$stune_group/$param" 2>/dev/null)
            if [ -n "$val" ]; then
                echo "write /dev/stune/$stune_group/$param $val" >> "$BACKUP_FILE"
            fi
        done
    fi
done

# ============================================
# Backup GPU values
# ============================================
echo "" >> "$BACKUP_FILE"
echo "# === GPU VALUES ===" >> "$BACKUP_FILE"
for gpu_path in \
    /sys/class/devfreq/13000000.mali \
    /sys/class/devfreq/mtk-devfreq-mali \
    /sys/devices/platform/soc/13000000.mali/devfreq/13000000.mali
do
    if [ -d "$gpu_path" ]; then
        for param in governor max_freq min_freq; do
            val=$(cat "$gpu_path/$param" 2>/dev/null)
            if [ -n "$val" ]; then
                echo "write $gpu_path/$param $val" >> "$BACKUP_FILE"
            fi
        done
        break
    fi
done

# ============================================
# Backup Touch values
# ============================================
echo "" >> "$BACKUP_FILE"
echo "# === TOUCH VALUES ===" >> "$BACKUP_FILE"
for touch_path in \
    /sys/devices/virtual/touch/touch_dev \
    /sys/devices/virtual/touch/touchscreen \
    /sys/class/touch/touch_dev
do
    if [ -d "$touch_path" ]; then
        for param in \
            touch_mode bump_sample_rate Touch_Active_MODE Touch_Edge_Filter \
            Touch_UP_THRESHOLD Touch_Tolerance Touch_Wgh_Max Touch_Wgh_Min \
            Touch_Wgh_Step Touch_Report_Rate; do
            val=$(cat "$touch_path/$param" 2>/dev/null)
            if [ -n "$val" ]; then
                echo "write $touch_path/$param $val" >> "$BACKUP_FILE"
            fi
        done
        break
    fi
done

# ============================================
# Backup System Properties
# ============================================
echo "" >> "$BACKUP_FILE"
echo "# === SYSTEM PROPERTY VALUES ===" >> "$BACKUP_FILE"
for prop in \
    debug.hwui.renderer ro.hwui.use_vulkan debug.hwui.use_vulkan \
    debug.renderengine.backend debug.renderengine.skipshadercache \
    debug.hwui.render_dirty_regions debug.hwui.skip_damage_region \
    debug.hwui.profile debug.hwui.show_dirty_regions \
    debug.sf.latch_unsignaled debug.sf.enable_hwc_vds \
    ro.surface_flinger.max_frame_buffer_acquired_buffers \
    dalvik.vm.dex2oat-threads dalvik.vm.image-dex2oat-threads \
    dalvik.vm.dex2oat-filter dalvik.vm.heapgrowthlimit \
    dalvik.vm.heapsize dalvik.vm.heapmaxfree dalvik.vm.heapminfree \
    dalvik.vm.heaptargetutilization dalvik.vm.dex2oat-swap \
    ro.sys.fw.bg_apps_limit ro.config.max_bg_processes \
    ro.lmk.zram_enabled \
    ro.vendor.inputdevices.use_xiaomi_touch \
    persist.vendor.touch.game.mode persist.vendor.touch.high.sample.rate; do
    val=$(getprop "$prop" 2>/dev/null)
    if [ -n "$val" ]; then
        echo "resetprop -n $prop $val" >> "$BACKUP_FILE"
    fi
done

# Backup MGLRU
echo "" >> "$BACKUP_FILE"
echo "# === MGLRU VALUES ===" >> "$BACKUP_FILE"
if [ -d "/sys/kernel/mm/lru_gen" ]; then
    for param in enabled min_ttl_ms; do
        val=$(cat "/sys/kernel/mm/lru_gen/$param" 2>/dev/null)
        if [ -n "$val" ]; then
            echo "write /sys/kernel/mm/lru_gen/$param $val" >> "$BACKUP_FILE"
        fi
    done
done

echo "" >> "$BACKUP_FILE"
echo "# === END OF BACKUP ===" >> "$BACKUP_FILE"

chmod 0644 "$BACKUP_FILE"
touch "$FLAG_FILE"
chmod 0644 "$FLAG_FILE"

# Lancelot Performance Booster

A KernelSU module for the **Redmi 9 (lancelot)** that optimizes kernel parameters, enables Vulkan rendering, boosts touch sampling rate, and tunes memory/GPU/network for maximum performance.

## Requirements

- **Device:** Xiaomi Redmi 9 (codename: `lancelot`) / Poco M2 (codename: `shiva`)
- **Root:** [KernelSU](https://kernelsu.org/) (Next or original)
- **Metamodule:** A mounting metamodule (e.g. [meta-overlayfs](https://github.com/KernelSU-Modules-Repo/meta-overlayfs)) if your module modifies `/system`
- **Android:** 10+ (tested on MIUI/HyperOS)

## Installation

1. Download the latest `lancelot-perf.zip` from [Releases](https://github.com/mochibunr/lanceperf/releases)
2. Open KernelSU Manager → Modules → Install from storage (➕)
3. Select the ZIP file
4. Reboot when prompted

### CLI

```bash
ksud module install /path/to/lancelot-perf.zip
```

## What It Does

### VFS Cache
| Parameter | Default | Tweaked | Effect |
|-----------|---------|---------|--------|
| `vfs_cache_pressure` | 100 | **10** | Kernel holds dentries/inodes much longer, faster file lookups |

### Memory
| Parameter | Default | Tweaked | Effect |
|-----------|---------|---------|--------|
| `swappiness` | 60 | 30 | Prefer RAM over swap |
| `dirty_ratio` | 20 | 30 | Batch writes for throughput |
| `dirty_background_ratio` | 10 | 5 | Start writeback earlier |
| `min_free_kbytes` | ~3000 | 16384 | More free RAM headroom |
| `zone_reclaim_mode` | 1 | 0 | Disable cross-zone reclaim |
| `page-cluster` | 3 | 0 | No swap readahead |
| MGLRU | varies | enabled | Better multi-gen LRU reclaim |

### Scheduler (CFS)
- Reduced `sched_latency_ns` (4ms) for snappier feel
- Lower `sched_min_granularity_ns` (0.5ms) for fairer scheduling
- Top-app `schedtune.boost = 1` and `prefer_idle = 1`
- Schedutil `up_rate_limit_us = 0` for instant frequency ramps

### I/O
- **BFQ** scheduler (better latency for interactive use)
- `read_ahead_kb = 256` for sequential reads
- `nr_requests = 64` for lower queue depth
- `iostats = 0` to save CPU cycles

### Touch Sampling Rate
- Xiaomi touch driver: game mode enabled, `bump_sample_rate = 1`, `Touch_Report_Rate = 1`
- MediaTek touch: report rate set to 240Hz
- Generic input: debounce reduced to 0

### Vulkan Renderer
- `debug.hwui.renderer = skiavk`
- `ro.hwui.use_vulkan = true`
- `debug.renderengine.backend = skiavk`
- Skip shader cache for faster app starts

### GPU (Mali-G52 MC2)
- Performance governor on GPU devfreq
- Max frequency set to 950MHz
- Min frequency set to 200MHz

### Network
- **BBR** congestion control (if kernel supports it)
- TCP buffer sizes tuned for throughput (16MB max)
- TCP Fast Open enabled
- Reduced `tcp_fin_timeout` (15s) and keepalive intervals

### System Properties
- Dalvik heap tuned for Helio G80 (256m growth limit, 512m max)
- 4-core dex2oat with `speed` filter
- Background app limit reduced to 32
- Touch game mode properties enabled

## Backup & Restore

On first boot, the module backs up all original values to:
```
/data/adb/lancelot-perf/backup.sh
```

When you **uninstall** the module, it automatically restores every value to its original state. No manual cleanup needed.

## OTA Updates

The module checks for updates via the KernelSU Manager. When a new release is published on GitHub, you'll see an "Update" button in the Modules section.

## Logs

Module logs are stored at:
```
/data/adb/lancelot-perf/perf.log
```

Check with:
```bash
su -c cat /data/adb/lancelot-perf/perf.log
```

## Uninstalling

1. KernelSU Manager → Modules → Lancelot Perf Booster → Remove
2. Reboot

All original values are restored automatically from backup.

## Module Structure

```
lancelot-perf/
├── module.prop          # Module metadata
├── service.sh           # Main boot script (late_start)
├── post-fs-data.sh      # Early boot tweaks + backup trigger
├── boot-completed.sh    # Post-boot final tweaks
├── backup.sh            # Saves/restores original values
├── system.prop          # Android properties
├── sepolicy.rule        # SELinux policy rules
├── customize.sh         # Installation script
├── uninstall.sh         # Restore on removal
├── update.json          # OTA update manifest
├── CHANGELOG.md         # Version history
└── README.md            # This file
```

## Troubleshooting

| Issue | Cause | Fix |
|-------|-------|-----|
| Module not mounting | No metamodule installed | Install [meta-overlayfs](https://github.com/KernelSU-Modules-Repo/meta-overlayfs) → reboot |
| Bootloop | Incompatible tweak | Hold power 10s → boot to safe mode (Vol Down) → disable module |
| Touch not improving | Touch driver path differs | Check `ls /sys/devices/virtual/touch/` for your device's node |
| Vulkan not working | GPU lacks Vulkan support | Module falls back to OpenGL automatically |
| Updates not showing | `update.json` not reachable | Ensure GitHub repo is public and URL is correct |

## Credits

- [KernelSU](https://kernelsu.org/) by tiann
- [KTweak](https://github.com/tytydraco/KTweak) for reference sysctl values
- [AKTune](https://github.com/iodn/android-kernel-tweaker) for adaptive tuning patterns

## License

MIT

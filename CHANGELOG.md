# Changelog

## v2.0
- Added Vulkan renderer (skiavk) support
- Added touch sampling rate boost (Xiaomi/MTK drivers)
- Added backup/restore system on uninstall
- Added KernelSU environment check during install
- Added OTA auto-updates via GitHub releases
- Added README and CHANGELOG
- Improved GPU tuning for Mali-G52 MC2
- Improved I/O scheduler handling (BFQ priority)
- Added MGLRU support
- Added sepolicy rules for touch nodes

## v1.0
- Initial release
- VFS cache pressure = 10
- Memory, scheduler, I/O, network optimizations
- System property tuning
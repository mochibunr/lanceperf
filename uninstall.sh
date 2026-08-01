#!/system/bin/sh
# Lancelot Performance Booster - Uninstall Script
# Runs when module is removed
# Restores original system values from backup

BACKUP_DIR=/data/adb/lancelot-perf
BACKUP_FILE=$BACKUP_DIR/backup.sh
LOGFILE=$BACKUP_DIR/uninstall.log

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOGFILE
}

log "=== Uninstall: Restoring original values ==="

# ============================================
# RESTORE FROM BACKUP
# ============================================
if [ -f "$BACKUP_FILE" ]; then
    log "Backup file found, restoring..."
    sh "$BACKUP_FILE"
    log "Backup restored successfully"
else
    log "No backup file found, skipping restore"
fi

# ============================================
# CLEANUP
# ============================================
# Remove backup and logs
rm -rf "$BACKUP_DIR"

log "=== Uninstall complete ==="

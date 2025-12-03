#!/bin/bash
# Script to clean up storage on root filesystem

set -e

echo "=== Storage Cleanup Script ==="
echo "Current disk usage:"
df -h / | tail -1

echo ""
echo "=== Cleaning up safe-to-remove items ==="

# 1. Clean APT cache (safe, can be re-downloaded)
echo "1. Cleaning APT cache..."
sudo apt clean
sudo apt autoclean
echo "   ✓ APT cache cleaned"

# 2. Remove old Ray sessions (keep only the latest)
echo "2. Cleaning old Ray sessions..."
if [ -d "/tmp/ray" ]; then
    # Keep only the latest session, remove others
    LATEST_SESSION=$(ls -td /tmp/ray/session_* 2>/dev/null | head -1)
    if [ -n "$LATEST_SESSION" ]; then
        find /tmp/ray -maxdepth 1 -type d -name "session_*" ! -path "$LATEST_SESSION" -exec rm -rf {} + 2>/dev/null || true
        echo "   ✓ Old Ray sessions cleaned (kept latest)"
    fi
fi

# 3. Clean CUDA repository cache (safe, can be re-downloaded)
echo "3. Cleaning CUDA repository cache..."
if [ -d "/var/cudnn-local-repo-ubuntu2204-9.10.2" ]; then
    sudo rm -rf /var/cudnn-local-repo-ubuntu2204-9.10.2
    echo "   ✓ CUDA repository cache cleaned"
fi

# 4. Clean old log files (keep recent ones)
echo "4. Cleaning old log files..."
sudo journalctl --vacuum-time=7d 2>/dev/null || true
sudo find /var/log -type f -name "*.log" -mtime +30 -delete 2>/dev/null || true
sudo find /var/log -type f -name "*.gz" -mtime +7 -delete 2>/dev/null || true
echo "   ✓ Old log files cleaned"

# 5. Clean snap cache (safe)
echo "5. Cleaning snap cache..."
sudo snap list --all | awk '/disabled/{print $1, $3}' | while read snapname revision; do
    sudo snap remove "$snapname" --revision="$revision" 2>/dev/null || true
done
echo "   ✓ Snap cache cleaned"

# 6. Clean pip cache (if exists)
echo "6. Cleaning pip cache..."
pip cache purge 2>/dev/null || true
echo "   ✓ Pip cache cleaned"

# 7. Clean temporary files older than 7 days
echo "7. Cleaning old temporary files..."
find /tmp -type f -atime +7 -delete 2>/dev/null || true
find /tmp -type d -empty -delete 2>/dev/null || true
echo "   ✓ Old temporary files cleaned"

# 8. Clean UV cache (if exists in default location)
echo "8. Cleaning UV cache (if in default location)..."
if [ -d "$HOME/.cache/uv" ]; then
    rm -rf "$HOME/.cache/uv"/*
    echo "   ✓ UV cache cleaned"
fi

echo ""
echo "=== Cleanup complete! ==="
echo "New disk usage:"
df -h / | tail -1

echo ""
echo "=== Summary of cleaned items ==="
echo "- APT cache"
echo "- Old Ray sessions"
echo "- CUDA repository cache"
echo "- Old log files"
echo "- Snap cache"
echo "- Pip cache"
echo "- Old temporary files"
echo "- UV cache"


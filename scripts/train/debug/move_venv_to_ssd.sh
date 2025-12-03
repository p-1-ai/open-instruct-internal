#!/bin/bash
# Script to move .venv to SSD and create a symlink

set -e

PROJECT_DIR="$HOME/repos/open-instruct"
VENV_DIR="$PROJECT_DIR/.venv"
SSD_ROOT=/mnt/disks/ssd
SSD_VENV="$SSD_ROOT/venv_open_instruct"

echo "=== Moving .venv to SSD ==="
echo "Project directory: $PROJECT_DIR"
echo "Current .venv location: $VENV_DIR"
echo "Target SSD location: $SSD_VENV"

# Check if .venv exists
if [ ! -d "$VENV_DIR" ]; then
    echo "Error: .venv directory not found at $VENV_DIR"
    exit 1
fi

# Check if it's already a symlink
if [ -L "$VENV_DIR" ]; then
    echo "Warning: .venv is already a symlink. Current target: $(readlink -f $VENV_DIR)"
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check disk space
VENV_SIZE=$(du -sb "$VENV_DIR" | cut -f1)
SSD_AVAIL=$(df -B1 "$SSD_ROOT" | tail -1 | awk '{print $4}')

if [ "$VENV_SIZE" -gt "$SSD_AVAIL" ]; then
    echo "Error: Not enough space on SSD. Need $(numfmt --to=iec-i --suffix=B $VENV_SIZE), available $(numfmt --to=iec-i --suffix=B $SSD_AVAIL)"
    exit 1
fi

echo ""
echo "Current .venv size: $(du -sh $VENV_DIR | cut -f1)"
echo "SSD available: $(df -h $SSD_ROOT | tail -1 | awk '{print $4}')"
echo ""

# If target already exists, ask what to do
if [ -d "$SSD_VENV" ]; then
    echo "Warning: Target directory $SSD_VENV already exists!"
    read -p "Remove existing directory and continue? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$SSD_VENV"
    else
        echo "Aborted."
        exit 1
    fi
fi

# Create parent directory
mkdir -p "$(dirname $SSD_VENV)"

echo "Moving .venv to SSD..."
# Move the directory
mv "$VENV_DIR" "$SSD_VENV"

echo "Creating symlink..."
# Create symlink
ln -s "$SSD_VENV" "$VENV_DIR"

echo ""
echo "✓ Successfully moved .venv to SSD!"
echo "  Original location: $VENV_DIR (now a symlink)"
echo "  Actual location: $SSD_VENV"
echo ""
echo "Verifying..."
if [ -L "$VENV_DIR" ] && [ -d "$SSD_VENV" ]; then
    echo "✓ Symlink is valid"
    echo "✓ Target directory exists"
    echo ""
    echo "New disk usage:"
    df -h / | tail -1
    df -h "$SSD_ROOT" | tail -1
else
    echo "✗ Error: Verification failed!"
    exit 1
fi


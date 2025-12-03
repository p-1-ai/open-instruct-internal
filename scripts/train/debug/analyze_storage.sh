#!/bin/bash
# Script to analyze storage usage on root filesystem

echo "=== Storage Analysis for /dev/root ==="
echo ""
df -h / | tail -1
echo ""

echo "=== Top 10 Largest Directories ==="
du -sh /* 2>/dev/null | sort -hr | head -10
echo ""

echo "=== Breakdown of /usr (24G total) ==="
echo "/usr/local: $(du -sh /usr/local 2>/dev/null | cut -f1)"
echo "  - CUDA: $(du -sh /usr/local/cuda-12.8 2>/dev/null | cut -f1)"
echo "  - Python libs: $(du -sh /usr/local/lib/python3.12 2>/dev/null | cut -f1)"
echo "  - Other libs: $(du -sh /usr/local/lib 2>/dev/null | cut -f1)"
echo "/usr/lib: $(du -sh /usr/lib 2>/dev/null | cut -f1)"
echo "/usr/bin: $(du -sh /usr/bin 2>/dev/null | cut -f1)"
echo ""

echo "=== Breakdown of /var (3.9G total) ==="
echo "/var/cudnn-local-repo: $(du -sh /var/cudnn-local-repo-ubuntu2204-9.10.2 2>/dev/null | cut -f1) (CAN BE REMOVED)"
echo "/var/lib/snapd: $(du -sh /var/lib/snapd 2>/dev/null | cut -f1)"
echo "/var/cache/apt: $(du -sh /var/cache/apt 2>/dev/null | cut -f1) (CAN BE CLEANED)"
echo ""

echo "=== Breakdown of /snap (4.4G total) ==="
du -sh /snap/* 2>/dev/null | sort -hr | head -5
echo ""

echo "=== Breakdown of /home (861M total) ==="
du -sh /home/* 2>/dev/null | sort -hr | head -5
echo ""

echo "=== Safe to Clean ==="
echo "1. /var/cudnn-local-repo-ubuntu2204-9.10.2 (~1.5G) - CUDA repository cache"
echo "2. /var/cache/apt (~1G) - APT package cache"
echo "3. Old snap revisions (~few hundred MB)"
echo ""
echo "Total potentially recoverable: ~2.5-3GB"


#!/bin/bash

# System cache cleanup script for better performance
# Safely cleans large cache directories

echo "🧹 System Cache Cleanup"
echo "======================"

# Calculate current cache usage
TOTAL_BEFORE=$(du -sh ~/.cache 2>/dev/null | awk '{print $1}')
echo "Current cache usage: $TOTAL_BEFORE"
echo ""

# 1. PACKAGE MANAGER CACHES
echo "1. Package manager caches:"

# Paru (AUR helper) cache - 2.1GB
if [[ -d ~/.cache/paru ]]; then
    PARU_SIZE=$(du -sh ~/.cache/paru | awk '{print $1}')
    echo "   🗑️  Cleaning paru cache ($PARU_SIZE)..."
    paru -Scc --noconfirm 2>/dev/null || rm -rf ~/.cache/paru/*
fi

# Pnpm (Node.js) cache - 334MB  
if [[ -d ~/.cache/pnpm ]]; then
    PNPM_SIZE=$(du -sh ~/.cache/pnpm | awk '{print $1}')
    echo "   🗑️  Cleaning pnpm cache ($PNPM_SIZE)..."
    pnpm store prune 2>/dev/null || rm -rf ~/.cache/pnpm/*
fi

# Pip (Python) cache - 72MB
if [[ -d ~/.cache/pip ]]; then
    PIP_SIZE=$(du -sh ~/.cache/pip | awk '{print $1}')
    echo "   🗑️  Cleaning pip cache ($PIP_SIZE)..."
    pip cache purge 2>/dev/null || rm -rf ~/.cache/pip/*
fi

# 2. BROWSER CACHE
echo ""
echo "2. Browser cache cleanup:"

# Brave browser cache - 1.5GB
if [[ -d ~/.cache/BraveSoftware ]]; then
    BRAVE_SIZE=$(du -sh ~/.cache/BraveSoftware | awk '{print $1}')
    echo "   🗑️  Cleaning Brave cache ($BRAVE_SIZE)..."
    # Keep profile but clear cache
    find ~/.cache/BraveSoftware -name "Cache*" -type d -exec rm -rf {} + 2>/dev/null
    find ~/.cache/BraveSoftware -name "Code Cache*" -type d -exec rm -rf {} + 2>/dev/null
    find ~/.cache/BraveSoftware -name "GPUCache*" -type d -exec rm -rf {} + 2>/dev/null
fi

# 3. SYSTEM CLEANUP
echo ""
echo "3. System-wide cleanup:"

# Journal logs (keep last 3 days)
if command -v journalctl >/dev/null 2>&1; then
    echo "   📰 Cleaning journal logs (keeping 3 days)..."
    sudo journalctl --vacuum-time=3d >/dev/null 2>&1
fi

# Thumbnail cache
if [[ -d ~/.cache/thumbnails ]]; then
    THUMB_SIZE=$(du -sh ~/.cache/thumbnails 2>/dev/null | awk '{print $1}')
    echo "   🖼️  Cleaning thumbnail cache ($THUMB_SIZE)..."
    rm -rf ~/.cache/thumbnails/*
fi

# Font cache
if command -v fc-cache >/dev/null 2>&1; then
    echo "   🔤 Rebuilding font cache..."
    fc-cache -f >/dev/null 2>&1
fi

# 4. TEMPORARY FILES
echo ""
echo "4. Temporary files:"

# Clear system temp (as user)
if [[ -d /tmp && -w /tmp ]]; then
    echo "   🗂️  Clearing user temp files..."
    find /tmp -user "$USER" -type f -name "*" -mtime +1 -delete 2>/dev/null || true
fi

# 5. CALCULATE SAVINGS
echo ""
echo "📊 Cleanup results:"
echo "==================="

TOTAL_AFTER=$(du -sh ~/.cache 2>/dev/null | awk '{print $1}')
echo "Cache usage before: $TOTAL_BEFORE"
echo "Cache usage after:  $TOTAL_AFTER"

# Show reclaimed space
if command -v numfmt >/dev/null 2>&1; then
    BEFORE_BYTES=$(du -sb ~/.cache 2>/dev/null | awk '{print $1}')
    AFTER_BYTES=$(du -sb ~/.cache 2>/dev/null | awk '{print $1}')
    SAVED_BYTES=$((BEFORE_BYTES - AFTER_BYTES))
    SAVED_HUMAN=$(echo "$SAVED_BYTES" | numfmt --to=iec)
    echo "Space reclaimed:    ~$SAVED_HUMAN"
fi

echo ""
echo "✅ Cache cleanup completed!"
echo ""
echo "🎯 Performance benefits:"
echo "   - Faster file operations"
echo "   - More available memory"  
echo "   - Reduced disk I/O"
echo "   - Quicker application startup"

# 6. CREATE AUTO CLEANUP SERVICE
echo ""
echo "🤖 Setting up weekly auto-cleanup..."

mkdir -p ~/.config/systemd/user
cat > ~/.config/systemd/user/cache-cleanup.service << 'EOF'
[Unit] 
Description=Weekly cache cleanup
Documentation=man:systemd.service(5)

[Service]
Type=oneshot
ExecStart=%h/.config/scripts/cache-cleanup.sh --auto
EOF

cat > ~/.config/systemd/user/cache-cleanup.timer << 'EOF'
[Unit]
Description=Run cache cleanup weekly
Documentation=man:systemd.timer(5)

[Timer]
OnCalendar=weekly
Persistent=true
RandomizedDelaySec=600

[Install]
WantedBy=timers.target
EOF

# Enable timer
systemctl --user daemon-reload 2>/dev/null
systemctl --user enable cache-cleanup.timer 2>/dev/null
systemctl --user start cache-cleanup.timer 2>/dev/null

echo "✅ Weekly auto-cleanup scheduled"
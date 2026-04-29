#!/bin/bash
set -euo pipefail

# Autoresearch script for Chromium HW acceleration stability
# Launches Chromium, waits, checks if Waybar/Hyprland survive

# Backup function for config files (used by agent during edits)
backup_config() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}.bak.$(date +%s)" 2>/dev/null || true
    fi
}

# Check if critical processes are running
check_processes() {
    if ! pgrep -x "Hyprland" > /dev/null; then
        echo "Hyprland not running"
        return 1
    fi
    if ! pgrep -x "waybar" > /dev/null; then
        echo "Waybar not running"
        return 1
    fi
    return 0
}

# Pre-check: Are DE processes running?
if ! check_processes; then
    echo "METRIC stability=0"
    exit 0
fi

# Launch Chromium with current flags (opens about:blank to minimize load)
echo "Launching Chromium..."
omarchy-launch-browser about:blank > /dev/null 2>&1 &
CHROMIUM_PID=$!

# Wait for Chromium to initialize and potential crash to manifest
sleep 15

# Post-check: Are DE processes still running?
if check_processes; then
    echo "METRIC stability=1"
    # Try to capture GPU info (headless, won't crash DE)
    GPU_INFO=$(chromium --headless=new --disable-gpu --dump-dom chrome://gpu 2>/dev/null | grep -E "WebGL|Canvas|Hardware|Acceleration" | head -5 || echo "GPU info unavailable")
    echo "GPU_STATUS: $GPU_INFO"
else
    echo "METRIC stability=0"
fi

# Cleanup: Kill Chromium if still running
pkill -f "chromium.*about:blank" 2>/dev/null || true
pkill -f "chromium.*chrome://gpu" 2>/dev/null || true

exit 0

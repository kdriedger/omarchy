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

# Launch Chromium with current flags (test with WebGL demo to stress GPU)
echo "Launching Chromium with GPU-intensive page..."
# Use a WebGL demo that stresses GPU
omarchy-launch-browser "https://webglsamples.org/aquarium/aquarium.html" > /dev/null 2>&1 &
CHROMIUM_PID=$!

# Wait for Chromium to initialize and potential crash to manifest
sleep 20

# Post-check: Are DE processes still running?
if check_processes; then
    echo "METRIC stability=1"
    # Try to capture GPU info via remote debugging
    echo "Attempting to capture GPU info..."
    # Kill any existing Chromium on debug port
    pkill -f "remote-debugging-port=9222" 2>/dev/null || true
    # Launch headless Chromium with debug port to fetch chrome://gpu
    chromium --headless=new --remote-debugging-port=9222 --disable-gpu chrome://gpu > /dev/null 2>&1 &
    DEBUG_PID=$!
    sleep 3
    # Fetch the GPU page via remote debugging API
    GPU_JSON=$(curl -s http://localhost:9222/json/page 2>/dev/null | grep -o '"webSocketDebuggerUrl":"[^"]*"' | head -1 | cut -d'"' -f4 || echo "")
    if [[ -n "$GPU_JSON" ]]; then
        echo "GPU_DEBUG_URL: $GPU_JSON"
    fi
    pkill -f "remote-debugging-port=9222" 2>/dev/null || true
    echo "GPU_STATUS: See chrome://gpu when manually launching Chromium"
else
    echo "METRIC stability=0"
fi

# Cleanup: Kill Chromium if still running
pkill -f "chromium.*about:blank" 2>/dev/null || true
pkill -f "chromium.*chrome://gpu" 2>/dev/null || true

exit 0

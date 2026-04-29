#!/bin/bash
# Fetch chrome://gpu report via remote debugging protocol
# Requires: chromium, curl, and optionally jq

PORT=9222
TMP_DIR=$(mktemp -d)

# Start Chromium with remote debugging in background
chromium --remote-debugging-port=$PORT --disable-gpu chrome://gpu > /dev/null 2>&1 &
CHROME_PID=$!

# Wait for Chromium to start
sleep 3

# Get the list of pages
PAGES=$(curl -s http://localhost:$PORT/json 2>/dev/null)

# Find the chrome://gpu page
GPU_PAGE=$(echo "$PAGES" | grep -o '"webSocketDebuggerUrl":"[^"]*"' | head -1 | cut -d'"' -f4)

if [[ -n "$GPU_PAGE" ]]; then
    echo "GPU Debug URL: $GPU_PAGE"
    echo "To view: Open Chrome and go to chrome://inspect, connect to localhost:$PORT"
else
    echo "Could not fetch GPU page via remote debugging"
    echo "Pages found: $PAGES"
fi

# Alternative: Get GPU info from logs
echo ""
echo "=== GPU Info from system ==="
glxinfo | grep -E "OpenGL vendor|OpenGL renderer" 2>/dev/null || echo "glxinfo not available"
vulkaninfo --summary 2>/dev/null | grep -E "GPU|device" | head -5 || echo "vulkaninfo not available"

# Cleanup
kill $CHROME_PID 2>/dev/null
wait $CHROME_PID 2>/dev/null
rm -rf $TMP_DIR

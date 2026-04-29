# Autoresearch: Chromium Hardware Acceleration without DE Crashes

## Objective
Get Chromium running with hardware acceleration enabled without crashing Waybar or Hyprland on NVIDIA GTX 1050.

## Metrics
- **Primary**: stability (binary, higher is better) — 1 = no crash after Chromium launch, 0 = Waybar/Hyprland crashed
- **Secondary**: gpu_status — output of chrome://gpu key indicators (to be captured)

## How to Run
`./autoresearch.sh` — launches Chromium with current flags, waits 10s, checks for DE processes, outputs `METRIC stability=1` or `METRIC stability=0`.

## Files in Scope
- `~/.config/chromium-flags.conf` — Chromium command-line flags (main lever for HW accel)
- `~/.config/hypr/envs.conf` — Environment variables for Hyprland session
- `~/.config/waybar/config.jsonc` — Waybar config (unlikely, but may need GPU tweaks)

## Off Limits
- `~/.local/share/omarchy/` — core Omarchy files (never modify)
- System-wide configs in `/etc/`

## Constraints
- Must not break other applications
- Must preserve existing user config (backup before changes)
- If DE crashes, user will restart and log experiment as crash

## What's Been Tried
- **Run 1-2**: Baseline tests with about:blank and WebGL demo - stability=1 (no crash) but chrome://gpu shows ALL HW acceleration DISABLED
- **chrome://gpu findings**: Canvas, Compositing, OpenGL, Rasterization, Video Decode/Encode, WebGL all DISABLED
- **WebGL error**: "BindToCurrentSequence failed" - GPU context creation failing
- **Root cause**: `--render-node-override=/dev/dri/renderD128` likely wrong for NVIDIA - NVIDIA doesn't use DRM render nodes same way
- NVIDIA GTX 1050 with proprietary drivers

## Notes
- chrome://gpu report can be captured via: `chromium --headless=new --remote-debugging-port=9222` + curl to fetch GPU page data
- Alternative: parse `chromium --enable-logging --v=1 2>&1 | grep -i gpu` for GPU init info
- Crashes may be due to NVIDIA driver bugs, Waybar's GPU usage, or Chromium's GPU process conflicts
- **NVIDIA + Wayland + Chromium**: May need `GBM_BACKEND=nvidia` env var, remove render-node-override
- **Next**: Fix flags to actually enable HW acceleration, then test for crashes

#!/bin/bash

# Simple auto-detection script for Polybar
# Designed to be called from launch.sh

CONFIG_DIR="$HOME/.config/bspwm/utility/polybar"
SYSTEM_INI="$CONFIG_DIR/system.ini"
LOG_FILE="$CONFIG_DIR/auto-detect.log"

# Quick mode for launch.sh
if [ "$1" = "--quick" ]; then
    # Check if already ran today
    if [ -f "$SYSTEM_INI" ]; then
        TODAY=$(date '+%Y%m%d')
        FILE_DATE=$(stat -c %y "$SYSTEM_INI" 2>/dev/null | cut -d' ' -f1 | tr -d '-')
        if [ "$FILE_DATE" = "$TODAY" ]; then
            echo "System already configured today" >> "$LOG_FILE"
            exit 0
        fi
    fi
fi

# Log function
log() {
    echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"
}

# Start detection
log "=== Starting system detection ==="

# Detect adapter
ADAPTER=$(ls /sys/class/power_supply/ 2>/dev/null | grep -E "^(AC|ADP|ac)" | head -1 || echo "AC")
log "Adapter: $ADAPTER"

# Detect battery
BATTERY=$(ls /sys/class/power_supply/ 2>/dev/null | grep -E "^(BAT|battery)" | head -1 || echo "BAT0")
log "Battery: $BATTERY"

# Detect graphics card
GRAPHICS_CARD=$(ls /sys/class/backlight/ 2>/dev/null | head -1 || echo "intel_backlight")
log "Graphics card: $GRAPHICS_CARD"

# Detect wireless interface
WIRELESS_IFACE="wlan0"
for iface in /sys/class/net/*; do
    if [ -d "$iface/wireless" ]; then
        WIRELESS_IFACE="${iface##*/}"
        break
    fi
done
log "Wireless interface: $WIRELESS_IFACE"

# Detect wired interface
WIRED_IFACE="eth0"
for iface in /sys/class/net/*; do
    ifname="${iface##*/}"
    if [[ "$ifname" =~ ^(en|eth) ]] && [ ! -d "$iface/wireless" ]; then
        WIRED_IFACE="$ifname"
        break
    fi
done
log "Wired interface: $WIRED_IFACE"

# Create/update system.ini
cat > "$SYSTEM_INI" << EOF
# Auto-generated on $(date '+%Y-%m-%d %H:%M:%S')
# Edit manually if needed

[system]
adapter = $ADAPTER
battery = $BATTERY
graphics_card = $GRAPHICS_CARD
network_interface_wireless = $WIRELESS_IFACE
network_interface_wired = $WIRED_IFACE
EOF

log "Configuration saved to system.ini"
echo "System configuration updated"

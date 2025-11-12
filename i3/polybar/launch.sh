#!/bin/bash
#Config Polybar For Multi-Monitor

# Matikan semua polybar yang masih jalan
killall -q polybar
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

CONFIG="$HOME/.config/polybar/config.ini"

PRIMARY=$(xrandr --query | grep "primary" | cut -d" " -f1)

if [ -n "$PRIMARY" ]; then
  MONITOR=$PRIMARY polybar -c "$CONFIG" --reload main&
else
  #Fallback if not there is primary, use the first monitor detected
  FIRST=$(xrandr --query | grep "Connected" | head -n1 | cut -d" " -f1)
  MONITOR=$FIRST polybar -c "$CONFIG"
fi

#!/bin/bash

while true; do
    # cek apakah ada window fullscreen
    if xprop -root | grep "_NET_ACTIVE_WINDOW(WINDOW)" >/dev/null; then
        WINID=$(xprop -root _NET_ACTIVE_WINDOW | awk -F' ' '{print $5}')
        if xprop -id "$WINID" | grep "_NET_WM_STATE_FULLSCREEN" >/dev/null; then
            pkill -x picom
        else
            if ! pgrep -x picom >/dev/null; then
                picom --experimental-backends --config "$HOME/.config/picom/picom.conf" &
            fi
        fi
    fi
    sleep 2
done


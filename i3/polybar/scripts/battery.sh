#!/bin/bash

# Ambil info dari upower (lebih universal)
battery=$(upower -i $(upower -e | grep BAT) | grep percentage | awk '{print $2}' | tr -d '%')
status=$(upower -i $(upower -e | grep BAT) | grep state | awk '{print $2}')

if [ "$status" = "charging" ]; then
    echo "  ${battery}%"
elif [ "$status" = "discharging" ]; then
    if [ "$battery" -le 20 ]; then
        echo "  ${battery}%"
    elif [ "$battery" -le 40 ]; then
        echo "  ${battery}%"
    elif [ "$battery" -le 60 ]; then
        echo "  ${battery}%"
    elif [ "$battery" -le 80 ]; then
        echo "  ${battery}%"
    else
        echo "  ${battery}%"
    fi
else
    echo "  ${battery}%"
fi

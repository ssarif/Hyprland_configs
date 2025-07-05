#!/bin/bash

# Set the threshold
THRESHOLD=30

# Get battery percentage (adjust BAT1 if needed)
BATTERY=$(cat /sys/class/power_supply/BAT1/capacity)

if [ "$BATTERY" -lt "$THRESHOLD" ]; then
    notify-send -u critical "Battery Low" "This is critical"
    paplay /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga
fi


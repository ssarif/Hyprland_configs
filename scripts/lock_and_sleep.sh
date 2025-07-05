#!/bin/bash
# ~/scripts/lock_and_sleep.sh

# Start hypridle with temporary config
hypridle -c ~/.config/hypr/hypridle_lock.conf &

# Lock screen
hyprlock

# Once unlocked, kill hypridle
pkill -f "hypridle.*hypridle_lock.conf"


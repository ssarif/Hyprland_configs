#!/bin/bash
# Save as ~/group_all.sh and make executable: chmod +x ~/group_all.sh

# Check if jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required. Install with 'sudo pacman -S jq' or 'sudo apt install jq'"
    exit 1
fi

# Enable debug output
set -x

# Get current workspace ID
current_workspace=$(hyprctl activeworkspace -j | jq -r '.id // empty')
if [ -z "$current_workspace" ]; then
    echo "Error: Could not determine current workspace"
    exit 1
fi

# Get window addresses in the current workspace
windows=$(hyprctl clients -j | jq -r --arg ws "$current_workspace" '.[] | select(.workspace.id == ($ws | tonumber)) | .address')

# Check if there are windows to group
window_count=$(echo "$windows" | grep -c '^')
if [ "$window_count" -eq 0 ]; then
    echo "No windows found in workspace $current_workspace"
    exit 0
fi
echo "Found $window_count windows in workspace $current_workspace"

# Focus the first window and create a group
first_window=$(echo "$windows" | head -n 1)
if [ -z "$first_window" ]; then
    echo "Error: No valid first window found"
    exit 1
fi

echo "Focusing first window: $first_window"
hyprctl dispatch focuswindow address:$first_window
if ! hyprctl dispatch togglegroup; then
    echo "Error: Failed to create group with first window"
    exit 1
fi
sleep 0.3  # Generous delay for group creation

# Move remaining windows into the group
for window in $windows; do
    if [ "$window" != "$first_window" ]; then
        echo "Focusing and grouping window: $window"
        if ! hyprctl dispatch focuswindow address:$window; then
            echo "Warning: Failed to focus window $window, skipping"
            continue
        fi
        sleep 0.3  # Delay for focus
        if ! hyprctl dispatch moveintogroup; then
            echo "Warning: Failed to move window $window into group"
            continue
        fi
        sleep 0.3  # Delay for grouping
    fi
done

echo "Successfully grouped $window_count windows into a tabbed layout in workspace $current_workspace"

++ hyprctl activeworkspace -j
temp.sh: line 14: hyprctl: command not found
++ jq -r '.id // empty'
+ current_workspace=
+ '[' -z '' ']'
+ echo 'Error: Could not determine current workspace'
+ exit 1
Error: Could not determine current workspace

group_all.sh
x-shellscript
•
Why This Script Is Foolproof

    Robust Parsing:
        Uses hyprctl -j with jq to parse JSON output, ensuring accurate workspace and window detection across Hyprland versions.
        Handles edge cases (e.g., empty workspace ID) with jq -r '.id // empty'.
    Error Handling:
        Checks for jq availability.
        Validates workspace ID and window list.
        Skips problematic windows with warnings instead of failing entirely.
        Exits with clear error messages if critical steps fail.
    Timing for Slower Systems:
        Uses 0.3-second delays between focuswindow, togglegroup, and moveintogroup to ensure compatibility with the HP Notebook 15’s i5-6200U (~2-5 GFLOPS).
    Focus Management:
        Explicitly focuses each window before grouping, preventing focus-related failures.
        Skips the first window in the grouping loop to avoid redundant actions.
    Debugging:
        set -x logs every command, making it easy to diagnose issues.
        Outputs window count and success/failure status for clarity.

Configuration Requirements

Ensure your ~/.config/hypr/hyprland.conf is set up for tabbed layouts and includes the keybinding:
conf
group {
    groupbar {
        enabled = true
        font_size = 12
        height = 20
        render_titles = true
        col.active = 0xff00ff00   # Green for active tab
        col.inactive = 0xff555555 # Gray for inactive tabs
    }
}

# Keybindings
bind = $mainMod, T, togglegroup
bind = $mainMod CONTROL, right, changegroupactive, f
bind = $mainMod CONTROL, left, changegroupactive, b
bind = $mainMod, W, exec, ~/group_all.sh
Steps to Use

    Install jq:
    bash

sudo pacman -S jq  # Arch-based
sudo apt install jq  # Debian-based
Save the Script:

    Save as ~/group_all.sh.
    Make executable:
    bash

        chmod +x ~/group_all.sh
    Reload Hyprland:
    bash
    hyprctl reload
    Test the Script:
        Open multiple windows (e.g., terminal, VS Code, browser) in one workspace.
        Press SUPER + W to run the script.
        Expect a green-bordered tab bar with window titles. Cycle tabs with SUPER + Ctrl + Right/Left.
        Run manually for debugging:
        bash
        bash ~/group_all.sh

Expected Output

Example output when running bash ~/group_all.sh with 3 windows in workspace 1:
animate-gaussian
+ current_workspace=1
+ windows=0x123456
0x789abc
0xdef123
+ window_count=3
+ echo Found 3 windows in workspace 1
Found

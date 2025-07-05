#!/bin/bash

# Check if required tools are installed
if ! command -v hyprctl &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: hyprctl or jq is not installed."
    exit 1
fi

# Get ID of current workspace
ws_id=$(hyprctl activeworkspace -j | jq '.id')
if [ -z "$ws_id" ]; then
    echo "Error: Could not retrieve workspace ID."
    exit 1
fi
echo "Current workspace ID: $ws_id"

# Get addresses of all windows in the current workspace
window_addrs=($(hyprctl clients -j | jq -r ".[] | select(.workspace.id == $ws_id and .floating == false and .fullscreen == 0 and .mapped == true) | .address"))
if [ ${#window_addrs[@]} -eq 0 ]; then
    echo "No eligible windows (non-floating, non-fullscreen, mapped) found in workspace $ws_id."
    exit 0
elif [ ${#window_addrs[@]} -lt 2 ]; then
    echo "Only one eligible window in workspace $ws_id. Tabbed layout requires at least two windows."
    exit 0
fi
echo "Eligible window addresses: ${window_addrs[@]}"

# Debug: List window details before grouping
echo "Window details before grouping:"
hyprctl clients -j | jq ".[] | select(.workspace.id == $ws_id) | {address: .address, floating: .floating, fullscreen: .fullscreen, mapped: .mapped, title: .title}"

# Function to focus a window with retries
focus_window() {
    local addr=$1
    local retries=3
    local attempt=1
    while [ $attempt -le $retries ]; do
        hyprctl dispatch focuswindow "address:$addr"
        if [ $? -eq 0 ]; then
            echo "Focused window $addr on attempt $attempt"
            return 0
        fi
        echo "Warning: Failed to focus window $addr on attempt $attempt"
        sleep 2
        attempt=$((attempt + 1))
    done
    echo "Error: Could not focus window $addr after $retries attempts"
    return 1
}

# Focus the first window and create a group
first_addr=${window_addrs[0]}
if ! hyprctl clients -j | jq -e ".[] | select(.address == \"$first_addr\")" > /dev/null; then
    echo "Error: First window $first_addr no longer exists."
    exit 1
fi
if ! focus_window "$first_addr"; then
    echo "Error: Failed to focus first window $first_addr."
    exit 1
fi
hyprctl dispatch togglefloating off "address:$first_addr"
sleep 2
hyprctl dispatch togglegroup
if [ $? -ne 0 ]; then
    echo "Error: Failed to create group for window $first_addr."
    exit 1
fi
echo "Created group for window $first_addr"
sleep 2

# Add remaining windows to the group
for addr in "${window_addrs[@]:1}"; do
    if ! hyprctl clients -j | jq -e ".[] | select(.address == \"$addr\")" > /dev/null; then
        echo "Warning: Window $addr no longer exists. Skipping."
        continue
    fi
    if ! focus_window "$addr"; then
        echo "Warning: Failed to focus window $addr. Skipping."
        continue
    fi
    hyprctl dispatch togglefloating off "address:$addr"
    sleep 2
    hyprctl dispatch togglegroup
    if [ $? -ne 0 ]; then
        echo "Warning: Failed to add window $addr to group. Skipping."
        continue
    fi
    echo "Added window $addr to group"
    sleep 2
done

# Debug: List window details after grouping
echo "Window details after grouping:"
hyprctl clients -j | jq ".[] | select(.workspace.id == $ws_id) | {address: .address, floating: .floating, fullscreen: .fullscreen, mapped: .mapped, title: .title}"

echo "All eligible windows in workspace $ws_id are now in a tabbed group."

#!/bin/bash

# Check current status
STATUS=$(nmcli networking)

if [ "$STATUS" = "enabled" ]; then
    # If enabled, turn it OFF
    nmcli networking off
    notify-send -u critical -t 3000 -i network-wireless-disconnected "Airplane Mode" "Enabled ✈️"
else
    # If disabled, turn it ON
    nmcli networking on
    notify-send -u low -t 3000 -i network-wireless-connected "Airplane Mode" "Disabled 📡"
fi
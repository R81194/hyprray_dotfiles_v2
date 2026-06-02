#!/bin/bash
# Cycles through asusctl power profiles

CURRENT=$(asusctl profile -p | grep "Active profile" | awk '{print $NF}')

if [ "$CURRENT" == "Quiet" ]; then
    asusctl profile -P Balanced
    notify-send -t 2000 "Power Profile" "Switched to Balanced"
elif [ "$CURRENT" == "Balanced" ]; then
    asusctl profile -P Performance
    notify-send -t 2000 "Power Profile" "Switched to Performance"
else
    asusctl profile -P Quiet
    notify-send -t 2000 "Power Profile" "Switched to Quiet"
fi
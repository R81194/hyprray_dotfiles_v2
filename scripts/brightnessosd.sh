#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Script for Monitor backlights (if supported) using brightnessctl

iDIR="$HOME/.config/swaync/icons"
notification_timeout=1000

# --- MODIFICATION START ---
# specific device detection to fix Hybrid/Integrated mode issues
# This looks for 'amdgpu', 'intel', or 'nvidia' backlights and ignores 'acpi_video0'
DEVICE=$(brightnessctl -l | grep -E "intel|nvidia" | head -n 1 | awk -F"'" '{print $2}')

if [ -z "$DEVICE" ]; then
    # Fallback: if no GPU backlight found, let brightnessctl pick default
    CMD="brightnessctl"
else
    # Target the specific GPU device found above
    CMD="brightnessctl -d $DEVICE"
fi
# --- MODIFICATION END ---

# Get brightness
get_backlight() {
    # Added $CMD to target the correct device
    echo $($CMD -m | cut -d, -f4)
}

# Get icons
get_icon() {
    current=$(get_backlight | sed 's/%//')
    if   [ "$current" -le "20" ]; then
        icon="$iDIR/brightness-20.png"
    elif [ "$current" -le "40" ]; then
        icon="$iDIR/brightness-40.png"
    elif [ "$current" -le "60" ]; then
        icon="$iDIR/brightness-60.png"
    elif [ "$current" -le "80" ]; then
        icon="$iDIR/brightness-80.png"
    else
        icon="$iDIR/brightness-100.png"
    fi
}

# Notify
notify_user() {
    notify-send -e -h string:x-canonical-private-synchronous:brightness_notif -h int:value:$current -u low -i "$icon" "Brightness : $current%"
}

# Change brightness
change_backlight() {
    # Added $CMD to target the correct device
    $CMD set "$1" && get_icon && notify_user
}

# Execute accordingly
case "$1" in
    "--get")
        get_backlight
        ;;
    "--inc")
        change_backlight "+2%"
        ;;
    "--dec")
        change_backlight "2%-"
        ;;
    *)
        get_backlight
        ;;
esac

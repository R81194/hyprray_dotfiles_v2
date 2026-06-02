#!/bin/bash

# --- CONFIGURATION ---
CHECK_FREQ=60 

# Initial state variables
last_status="Unknown"
mode_switched=false

while true; do
    # 1. Find Battery
    BAT_PATH=$(find /sys/class/power_supply/ -name "BAT*" | head -n 1)
    
    if [ -z "$BAT_PATH" ]; then
        sleep 60
        continue
    fi

    # Read values
    capacity=$(cat "$BAT_PATH/capacity")
    status=$(cat "$BAT_PATH/status")

    # 2. Reset if Charging
    if [ "$status" = "Charging" ] && [ "$last_status" != "Charging" ]; then
        # Optional: Ask to reset to balanced when plugged in
        # (pkexec runs in background '&' so it doesn't block the loop)
        (pkexec auto-cpufreq --force=reset) &
        
        notify-send -u low -i "battery-charging" "Power Monitor" "Charging... Password requested to reset mode."
        mode_switched=false
        
        # Clear warning flags
        rm -f /tmp/bat_warn_*
    fi
    
    last_status="$status"

    # 3. Discharging Logic
    if [ "$status" = "Discharging" ]; then
        
        # --- LEVEL 20%: Trigger Password Popup for Power Saver ---
        if [ "$capacity" -le 20 ] && [ "$mode_switched" = false ]; then
            notify-send -u normal -i "battery-low" "Battery Low ($capacity%)" "Requesting Password for Power Saver..."
            
            # This triggers the GUI password prompt in the background
            (pkexec auto-cpufreq --force=powersave) &
            
            mode_switched=true
        fi

        # --- CRITICAL WARNINGS (No Password Needed) ---
        
        # 15% Warning
        if [ "$capacity" -le 15 ] && [ ! -f /tmp/bat_warn_15 ]; then
            notify-send -u critical -i "battery-caution" "Battery Low" "Level is at $capacity%. Please plug in."
            touch /tmp/bat_warn_15

            (pkexec auto-cpufreq --force=powersave) &
            
            mode_switched=true
        fi

        # 10% Warning
        if [ "$capacity" -le 10 ] && [ ! -f /tmp/bat_warn_10 ]; then
            notify-send -u critical -i "battery-caution" "Battery Critical" "Level is at $capacity%. Save your work!"
            touch /tmp/bat_warn_10

            (pkexec auto-cpufreq --force=powersave) &
            
            mode_switched=true
        fi

        # 5% Warning
        if [ "$capacity" -le 5 ] && [ ! -f /tmp/bat_warn_5 ]; then
            notify-send -u critical -i "battery-empty" "Battery Dying" "Level is at $capacity%. System will die soon."
            touch /tmp/bat_warn_5

            (pkexec auto-cpufreq --force=powersave) &
            
            mode_switched=true
        fi

        # 2% Warning
        if [ "$capacity" -le 2 ] && [ ! -f /tmp/bat_warn_2 ]; then
            notify-send -u critical -i "battery-empty" "HIBERNATING SOON" "Battery at $capacity%. Goodbye."
            touch /tmp/bat_warn_2
        fi
    fi

    sleep $CHECK_FREQ
done
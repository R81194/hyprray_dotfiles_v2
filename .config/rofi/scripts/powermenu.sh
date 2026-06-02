#!/bin/bash

theme="$HOME/.config/rofi/powermenu.rasi"

shutdown=""
reboot=""
lock=""
suspend=""
logout=""

options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"

selected_option=$(echo -e "$options" | rofi -dmenu -hover-select -click-to-exit -theme "$theme")

case $selected_option in
    $lock)
        hyprlock
        ;;
    $suspend)
        systemctl suspend
        ;;
    $logout)
        hyprctl dispatch exit
        ;;
    $reboot)
        systemctl reboot
        ;;
    $shutdown)
        systemctl poweroff
        ;;
esac

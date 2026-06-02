#!/bin/bash

# If Focus Mode is active, exit the script immediately
if [ -f /tmp/focus_mode ]; then exit 0; fi

# 1. Setup Paths
THEME_DIR="$HOME/.config/waybar"
ROFI_THEME="$HOME/.config/rofi/waybar-switcher.rasi"

# 2. Select Layout using your Glassy Rofi theme
# We filter out 'themes' or 'scripts' folders if they exist to only show layout names
CHOICE=$(ls -d "$THEME_DIR"/*/ | xargs -n 1 basename | grep -vE 'scripts|themes' | rofi -dmenu -p "󱊄 Layout" -theme "$ROFI_THEME" -i)

# If no choice was made (ESC pressed), exit
if [ -z "$CHOICE" ]; then
    exit 0
fi

# 3. THE FIX: Update symlinks so Waybar & Wallpaper switcher always find the right files
# This makes ~/.config/waybar/config.jsonc point to your selected theme
ln -sfn "$THEME_DIR/$CHOICE/config.jsonc" "$HOME/.config/waybar/config.jsonc"
ln -sfn "$THEME_DIR/$CHOICE/style.css" "$HOME/.config/waybar/style.css"

# 4. Restart Waybar
killall waybar

# Wait a tiny bit to ensure it's closed
sleep 0.2

# Launch Waybar using the new symlinks
waybar &
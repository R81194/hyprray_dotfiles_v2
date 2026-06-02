#!/bin/bash

# If Focus Mode is active, exit the script immediately
if [ -f /tmp/focus_mode ]; then exit 0; fi

WALLPAPER_DIR="/home/noir_ray/Pictures/wallpapers"
# Point this to wherever you cloned the repo
CHROMIUM_PYWAL_DIR="/home/noir_ray/.config/scripts/ChromiumPywal" 

# 1. Pick a random image (explicitly targeting .jpg, .png, and .gif) and save it
RANDOM_WALL="$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | shuf -n 1)"

# ------------------------------------------
# PYWAL INTEGRATION START
# ------------------------------------------

# 2. Generate Colors (Pywal uses the first frame of a .gif for the palette)
# The -n flag stops Pywal from setting the wallpaper, since awww will do it
if ! wal -i "$RANDOM_WALL" -n; then
    # Fallback to grayscale if Pywal fails (e.g., image is monochrome)
    notify-send "($RANDOM_WALL) probably monochrome" -h "string:x-canonical-private-synchronous:wallpaper_notif"  "Using Grayscale Theme"
    wal -i "$RANDOM_WALL" 
    wal --theme base16-grayscale
fi

# 3. Reload Hyprland to apply the newly generated Pywal border colors
hyprctl reload

# 4. Restart Waybar so it can grab the updated Pywal CSS palette
killall waybar
waybar & disown

# 5. Reload SwayNC (Notification Center) to apply new colors
swaync-client -rs 

# 6. Generate Brave Pywal Theme
if [ -d "$CHROMIUM_PYWAL_DIR" ]; then
    pushd "$CHROMIUM_PYWAL_DIR" > /dev/null
    ./generate-theme.sh
    popd > /dev/null
else
    echo "Brave theme script not found at $CHROMIUM_PYWAL_DIR"
fi
# ------------------------------------------
# PYWAL INTEGRATION END
# ------------------------------------------

# 7. Set the wallpaper (handles both static images and animated GIFs)
awww img "$RANDOM_WALL" \
 --transition-type any \
 --transition-duration 0.9 \
 --transition-fps 144

# Optional: Notification so you know exactly which file was picked
notify-send "Random Wallpaper" -h "string:x-canonical-private-synchronous:wallpaper_notif" "$(basename "$RANDOM_WALL")\n(Reload Brave extension to apply theme)"
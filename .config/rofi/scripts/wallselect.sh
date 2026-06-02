#!/bin/bash

# If Focus Mode is active, exit the script immediately
if [ -f /tmp/focus_mode ]; then exit 0; fi

# Define paths and variables (Do not change these)
WALL_DIR="$HOME/Pictures/wallpapers"
ROFI_THEME="$HOME/.config/rofi/wallselect.rasi"
CHROMIUM_PYWAL_DIR="/home/noir_ray/.config/scripts/ChromiumPywal"
TRANSITION_TYPE="wave" 
TRANSITION_DURATION="1.5" 

# Check if awww is running; if not, start the daemon in the background
if ! pgrep -x "awww-daemon" > /dev/null; then
    awww-daemon &
    sleep 0.5
fi

# Function to grab all valid images (now including .gif) and format them for Rofi with icons
list_wallpapers() {
    find "$WALL_DIR" -maxdepth 1 -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" -o -iname "*.gif" \) -print0 | sort -z | while IFS= read -r -d '' file; do
        filename=$(basename "$file")
        echo -en "$filename\0icon\x1f$file\n"
    done
}

# Open Rofi menu and wait for the user to select an image or gif
selected=$(list_wallpapers | rofi -dmenu -i -hover-select -click-to-exit -theme "$ROFI_THEME" -p "Wallpaper" -show-icons -[no-]click-to-exit )

# If a selection was made (user didn't just press Escape), proceed with setting it
if [ -n "$selected" ]; then
    full_path="$WALL_DIR/$selected"

    # ------------------------------------------
    # PYWAL INTEGRATION START
    # ------------------------------------------
    
    # 1. Generate Colors based on the selected image/gif frame
    # -n : Skip setting the wallpaper (awww handles that)
    # -q : Quiet mode (less output)
    if ! wal -i "$full_path" -n; then
    # Fallback to grayscale if Pywal fails (e.g., image is monochrome)
    notify-send "($selected) probably monochrome" -h "string:x-canonical-private-synchronous:wallpaper_notif"  "Using Grayscale Theme"
    wal -i "$full_path" 
    wal --theme base16-grayscale
    fi

    # 2. Reload Hyprland to update border colors with the new Pywal theme
    hyprctl reload

    # 3. Reload Waybar to apply the new CSS colors
    # We use '& disown' so the script doesn't wait for Waybar to close
    killall waybar
    waybar & disown
    
    # Reload SwayNC (Notification Center) to apply new colors
    swaync-client -rs 

    #Brave Pywal integration
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
    
    # Apply the chosen wallpaper (static or animated) using awww
    awww img "$full_path" \
        --transition-type "$TRANSITION_TYPE" \
        --transition-duration "$TRANSITION_DURATION" \
        --transition-fps 60 \
        --transition-bezier .65,0,.35,1 \
        --transition-step 255
        
    # Send a notification confirming the change, using the selected image as the icon
    notify-send "Wallpaper Changed" -h "string:x-canonical-private-synchronous:wallpaper_notif" "$selected" -i "$full_path"
fi
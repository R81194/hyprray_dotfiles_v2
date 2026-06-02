#!/usr/bin/env bash

# State Files
STATE_FILE="/tmp/focus_mode"
WAYBAR_STATE="/tmp/focus_waybar_state"
FOCUS_CONF="$HOME/.config/hypr/conf/focus.conf"

# --- CONFIGURATION ---
FOCUS_WP="$HOME/Pictures/wallpapers/minimalarch.png"
AESTHETIC_WP="$HOME/Pictures/wallpapers/wall1.jpg"

# Kitty Settings
KITTY_CONF="$HOME/.config/kitty/kitty.conf"
AESTHETIC_OPACITY="0.5" 

# Waybar Settings
# Make sure this matches the exact folder name of your minimal waybar
MINIMAL_WAYBAR_DIR="$HOME/.config/waybar/Minimal" 
# ---------------------

if [ ! -f "$STATE_FILE" ]; then
    # --- TURN FOCUS MODE ON ---
    touch "$STATE_FILE" 
    
    # 1. Write the overrides directly to the focus config file
    cat <<EOF > "$FOCUS_CONF"
animations {
    enabled = 0
}
decoration {
    rounding = 0
    blur {
        enabled = 0
    }
    shadow {
        enabled = 0
    }
}
general {
    gaps_in = 0
    gaps_out = 0
    border_size = 0
}
EOF

    hyprctl reload > /dev/null

    # 2. Make Kitty Opaque
    sed -i "s/^background_opacity.*/background_opacity 1.0/g" "$KITTY_CONF"
    killall -SIGUSR1 kitty
    
    # 3. Pywal Integration
    wal -q -t -n -i "$FOCUS_WP"
    
    # 4. WAYBAR: Save current layout and switch to minimal
    # Get the real folder path that the current config points to
    CURRENT_WAYBAR_CONFIG=$(readlink -f "$HOME/.config/waybar/config.jsonc")
    CURRENT_WAYBAR_DIR=$(dirname "$CURRENT_WAYBAR_CONFIG")
    
    # Save that directory so we can restore it later
    echo "$CURRENT_WAYBAR_DIR" > "$WAYBAR_STATE"

    # Link the minimal layout
    ln -sfn "$MINIMAL_WAYBAR_DIR/config.jsonc" "$HOME/.config/waybar/config.jsonc"
    ln -sfn "$MINIMAL_WAYBAR_DIR/style.css" "$HOME/.config/waybar/style.css"
    
    # Restart Waybar and detach it from the script
    killall waybar
    sleep 0.2
    waybar > /dev/null 2>&1 & disown

    # Reload SwayNC
    swaync-client -rs           
    
    # 5. Set Wallpaper
    awww img "$FOCUS_WP" --transition-type none
    
    notify-send "Hyprland" "FOCUS MODE ON: Distraction-Free Theme"
else
    # --- TURN FOCUS MODE OFF ---
    rm "$STATE_FILE" 
    
    # 1. Empty the override config file and reload
    > "$FOCUS_CONF"
    hyprctl reload > /dev/null

    # 2. Restore Kitty Transparency
    sed -i "s/^background_opacity.*/background_opacity $AESTHETIC_OPACITY/g" "$KITTY_CONF"
    killall -SIGUSR1 kitty
    
    # 3. Pywal Integration
    wal -q -t -n -i "$AESTHETIC_WP"
    
    # 4. WAYBAR: Restore the exact layout you were using before
    if [ -f "$WAYBAR_STATE" ]; then
        OLD_WAYBAR_DIR=$(cat "$WAYBAR_STATE")
        
        ln -sfn "$OLD_WAYBAR_DIR/config.jsonc" "$HOME/.config/waybar/config.jsonc"
        ln -sfn "$OLD_WAYBAR_DIR/style.css" "$HOME/.config/waybar/style.css"
        
        # Clean up the state file
        rm "$WAYBAR_STATE"
    fi

    # Restart Waybar and detach it
    killall waybar
    sleep 0.2
    waybar > /dev/null 2>&1 & disown

    # Reload SwayNC
    swaync-client -rs
        
    # 5. Set Wallpaper
    awww img "$AESTHETIC_WP" --transition-type wipe --transition-angle 30
    
    notify-send "Hyprland" "FOCUS MODE OFF: Aesthetic Mode Restored"
fi
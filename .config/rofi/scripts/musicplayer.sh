#!/bin/bash

# --- Configuration ---
CACHE_DIR="$HOME/.cache/rofi-music"
COVER_IMG="$CACHE_DIR/cover.jpg"
LIKED_FILE="$HOME/liked_songs.txt"
THEME_FILE="$HOME/.config/rofi/musicplayer.rasi"

mkdir -p "$CACHE_DIR"

# --- Get Media Status ---
STATUS=$(playerctl status 2>/dev/null)

if [ "$?" -ne 0 ] || [ -z "$STATUS" ]; then
    rofi -e "❌ No music playing"
    exit 1
fi

# --- Get Metadata ---
ARTIST=$(playerctl metadata artist)
TITLE=$(playerctl metadata title)
ALBUM=$(playerctl metadata album)
ART_URL=$(playerctl metadata mpris:artUrl)
VOLUME=$(playerctl volume | awk '{ printf "%.0f%%", $1 * 100 }')

# --- Handle Cover Art ---
# If art URL is different from last run, or file missing, fetch it
if [ ! -f "$COVER_IMG" ] || [ "$ART_URL" != "$(cat $CACHE_DIR/last_url 2>/dev/null)" ]; then
    if [[ "$ART_URL" == file://* ]]; then
        cp "${ART_URL#file://}" "$COVER_IMG"
    elif [[ "$ART_URL" == http* ]]; then
        curl -s -o "$COVER_IMG" "$ART_URL"
    else
        # Fallback if no art found (create a 1x1 black pixel or use placeholder)
        convert -size 500x500 xc:#1e1e2e "$COVER_IMG" 2>/dev/null
    fi
    echo "$ART_URL" > "$CACHE_DIR/last_url"
fi

# --- Icons (Nerd Fonts) ---
PREV="⏮"
NEXT="⏭"
if [ "$STATUS" = "Playing" ]; then
    PLAY_PAUSE="⏸"
else
    PLAY_PAUSE="⏵"
fi
VOL_UP="🔊"
VOL_DOWN="🔉"
HEART="♥" 

# --- Build the Menu Display ---
# We use the 'mesg' to show Song Title, Artist, and Volume
DISPLAY_TEXT="<b>$TITLE</b>\n<span size='small'>$ARTIST</span>\n<span size='x-small' alpha='50%'>$ALBUM • Vol: $VOLUME</span>"

# Define the buttons in order
OPTIONS="$PREV\n$PLAY_PAUSE\n$NEXT\n$VOL_DOWN\n$VOL_UP\n$HEART"

# --- Run Rofi ---
# We pass the cover image dynamically into the theme using -theme-str
SELECTED=$(echo -e "$OPTIONS" | rofi -dmenu -i -p "Music" \
    -theme "$THEME_FILE" \
    -theme-str "window { background-image: url(\"$COVER_IMG\", height); }" \
    -mesg "$DISPLAY_TEXT" \
    -selected-row 1)

# --- Handle Button Clicks ---
case "$SELECTED" in
    "$PREV")
        playerctl previous
        "$0" & # Restart script to refresh UI
        ;;
    "$PLAY_PAUSE")
        playerctl play-pause
        "$0" & 
        ;;
    "$NEXT")
        playerctl next
        "$0" & 
        ;;
    "$VOL_UP")
        playerctl volume 0.05+
        "$0" & 
        ;;
    "$VOL_DOWN")
        playerctl volume 0.05-
        "$0" & 
        ;;
    "$HEART")
        # Save to a local file
        echo "$ARTIST - $TITLE ($ALBUM)" >> "$LIKED_FILE"
        notify-send "❤️ Liked" "$TITLE by $ARTIST saved to favorites."
        "$0" &
        ;;
esac
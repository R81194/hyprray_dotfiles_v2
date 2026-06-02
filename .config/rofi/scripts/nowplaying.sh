#!/bin/bash

# --- Configuration ---
art_file="$HOME/.config/scripts/nowplaying/album_art.jpg"
fallback_art_file="$HOME/.config/scripts/nowplaying/fallback_album_art.jpg"
rofi_theme="$HOME/.config/rofi/nowplaying.rasi"
cache_file="$HOME/.config/scripts/nowplaying/song_title.cache"

# --- Helper Functions ---
escape_characters() {
    echo "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'
}

url_decode() {
    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

# --- Main Loop ---
while true; do

    # 1. Determine active player
    players_list=$(playerctl -l 2>/dev/null)
    active_player=""
    active_player_priority=0 

    while IFS= read -r player; do
        if [ -z "$player" ]; then continue; fi

        status=$(playerctl -p "$player" status 2>/dev/null | tr '[:upper:]' '[:lower:]')
        title=$(playerctl -p "$player" metadata title 2>/dev/null)

        # Priority Levels:
        # 3 = Playing, 2 = Paused, 1 = Stopped (with media), 0 = Ghost
        current_priority=0
        if [ "$status" == "playing" ]; then
            current_priority=3
        elif [ "$status" == "paused" ]; then
            current_priority=2
        elif [ -n "$title" ]; then
            current_priority=1
        else
            current_priority=0
        fi

        if [ "$current_priority" -gt "$active_player_priority" ]; then
            active_player="$player"
            active_player_priority=$current_priority
        fi
    done <<< "$players_list"

    # 2. Cleanup if no player
    if [[ -z "$active_player" ]]; then
        rm "$art_file" 2>/dev/null
        rm "$cache_file" 2>/dev/null    
    fi

    # 3. Default Data
    song_title="Nothing Playing"
    song_artist="Unknown"
    player_display_name=""

    # 4. Fetch Metadata (Only if player exists)
    if [[ -n "$active_player" ]]; then
        raw_title=$(playerctl -p "$active_player" metadata title 2>/dev/null)
        raw_artist=$(playerctl -p "$active_player" metadata artist 2>/dev/null)
        
        clean_name="${active_player%%.*}" 
        clean_name="$(tr '[:lower:]' '[:upper:]' <<< ${clean_name:0:1})${clean_name:1}"
        player_display_name=$(escape_characters "$clean_name")
        song_title=$(escape_characters "$raw_title")
        song_artist=$(escape_characters "$raw_artist")

        # Handle Art
        cached_title=""
        if [[ -f "$cache_file" ]]; then cached_title=$(cat "$cache_file"); fi
        
        if [[ "$raw_title" != "$cached_title" ]] || [[ ! -f "$art_file" ]]; then
            echo "$raw_title" > "$cache_file"
            album_art_url=$(playerctl -p "$active_player" metadata mpris:artUrl 2>/dev/null)

            if [[ -z "$album_art_url" ]]; then
                cp "$fallback_art_file" "$art_file" 2>/dev/null
            elif [[ "$album_art_url" =~ ^data:image ]]; then
                base64_data=$(echo "$album_art_url" | cut -d',' -f2)
                echo "$base64_data" | base64 -d > "$art_file" 2>/dev/null
            elif [[ "$album_art_url" =~ ^file:// ]]; then
                raw_path="${album_art_url#file://}"
                decoded_path="$(url_decode "$raw_path")"          
                cp "$decoded_path" "$art_file"        
            elif [[ "$album_art_url" =~ ^https:// ]]; then
                curl -s "$album_art_url" --output "$art_file"
            fi
        fi
    fi

    # 5. Define Icons & Status
    pre=""
    toogle=""
    next=""
    player_status=""
    notify_status="Paused"

    status=$(playerctl -p "$active_player" status 2>/dev/null)
    if [[ "$status" != "Playing" ]]; then
        toogle=""
        player_status="Paused"
        notify_status="Playing"    
    fi

    display_text="<span weight='light' size='small' alpha='50%'>${player_display_name} ${player_status}</span>\n\n${song_title}\n<span size='small' style='italic' alpha='65%'>${song_artist}</span>"

    # 6. Launch Rofi with Single Click & Persistence settings
    # -hover-select: Selects entry when mouse hovers over it
    # -me-select-entry '': Unbinds left click from "selecting" (preparing)
    # -me-accept-entry 'MousePrimary': Binds left click to "accepting" (executing)
    
    selected_option=$(echo -e "$pre\n$toogle\n$next" | rofi -dmenu \
        -theme "$rofi_theme" \
        -theme-str "textbox-custom { str: \"$display_text\"; }" \
        -select "$toogle" \
        -hover-select \
        -me-select-entry '' \
        -me-accept-entry 'MousePrimary')

    # 7. Check if user exited (Escape key or clicking outside)
    if [ $? -ne 0 ] || [ -z "$selected_option" ]; then
        exit 0
    fi

    # 8. Execute Action
    case "$selected_option" in
        "$pre") 
            playerctl -p "$active_player" previous 
            # Optional: Comment out notify if it gets annoying in persistent mode
            notify-send -h string:x-canonical-private-synchronous:media_notif "$player_display_name Skipped" "\n<big>$song_title</big>\n$song_artist" --icon="$art_file"
            ;;
        "$toogle") 
            playerctl -p "$active_player" play-pause 
            notify-send -h string:x-canonical-private-synchronous:media_notif "$player_display_name $notify_status" "\n<big>$song_title</big>\n$song_artist" --icon="$art_file"
            ;;
        "$next")
            playerctl -p "$active_player" next      
            notify-send -h string:x-canonical-private-synchronous:media_notif "$player_display_name Skipped" "\n<big>$song_title</big>\n$song_artist" --icon="$art_file"
            ;;
    esac

    # Small sleep to allow playerctl to process the command before we redraw
    sleep 0.1

done
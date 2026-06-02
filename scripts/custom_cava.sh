#!/bin/bash

# --- CONFIGURATION ---
bar_count=12
dict=" ▂▃▄▅▆▇█"

# "0" = Bars scale with Volume (True Reactivity)
# "1" = Bars are always big (Auto-Gain)
autosens=0 

# If autosens is 0, adjust this to make max volume fill the bars
# Higher number = taller bars
sensitivity=30
# ---------------------

# Kill old instances to prevent duplicates
pkill -f "cava -p /tmp/cava_hyprlock.conf"

# Create config with explicit PulseAudio/Pipewire targeting
cat <<EOF > /tmp/cava_hyprlock.conf
[general]
bars = $bar_count
framerate = 60
autosens = $autosens
sensitivity = $sensitivity
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

# Run Cava
# We force the audio environment variables just in case Hyprlock misses them
cava -p /tmp/cava_hyprlock.conf | while read -r line; do
    output=""
    all_zero=1
    
    IFS=';' read -ra levels <<< "$line"
    
    for level in "${levels[@]}"; do
        # Sanity check: ensure level is a number
        if [[ ! "$level" =~ ^[0-9]+$ ]]; then continue; fi
        
        # Silence detection
        if [ "$level" -gt 0 ]; then all_zero=0; fi
        
        # Add bar + gap
        output+="${dict:$level:1} "
    done

    # Hide if silent, otherwise update file
    if [ "$all_zero" -eq 1 ]; then
        echo "" > /tmp/hyprlock_cava_output
    else
        echo "${output% }" > /tmp/hyprlock_cava_output
    fi
done
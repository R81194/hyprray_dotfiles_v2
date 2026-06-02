#!/bin/bash

# 1. Get the coordinates. -w 0 removes the black border.
GEOM=$(slurp -w 0)

# 2. Exit silently if you press Escape to cancel the selection
if [ -z "$GEOM" ]; then
    exit 0
fi

# 3. Brief pause to let the screen clear before snapping
sleep 0.1

# 4. Save the exact filename to a variable so it stays consistent
FILEPATH="$HOME/Pictures/Screenshots/Screenshot_$(date +%F_%T).png"

# 5. Take the screenshot

# Tell grim to output to standard out (-), and pipe it into swappy
grim -g "$GEOM" - | swappy -f - -o "$FILEPATH"

# 6. Send the notification
notify-send -e "󰸉 Screenshot Saved" "$(basename "$FILEPATH")"
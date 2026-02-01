#!/bin/bash
# Screenshot window (quick save + clipboard)

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

FILENAME="screenshot_window_$(date +%Y-%m-%d_%H-%M-%S).png"
FILEPATH="$SCREENSHOT_DIR/$FILENAME"

# Get window geometry using slurp to click on window
GEOMETRY=$(swaymsg -t get_tree | jq -r '.. | select(.pid? and .visible?) | .rect | "\(.x),\(.y) \(.width)x\(.height)"' | slurp)

if [ -n "$GEOMETRY" ]; then
    grim -g "$GEOMETRY" "$FILEPATH"
    
    if [ -f "$FILEPATH" ]; then
        # Copy to clipboard
        wl-copy < "$FILEPATH"
        
        # Show notification with preview
        notify-send -i "$FILEPATH" "Window Screenshot" "Saved to $FILEPATH and copied to clipboard"
    fi
else
    notify-send "Screenshot Cancelled" "No window selected"
fi

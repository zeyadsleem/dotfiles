#!/bin/bash
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"
FILENAME="screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
FILEPATH="$SCREENSHOT_DIR/$FILENAME"
grim -g "$(slurp)" "$FILEPATH"
if [ -f "$FILEPATH" ]; then
    wl-copy < "$FILEPATH"
    notify-send -i "$FILEPATH" "Screenshot Saved" "Saved to $FILEPATH and copied to clipboard"
else
    notify-send "Screenshot Cancelled" "No area selected"
fi

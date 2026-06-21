#!/bin/bash
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"
FILENAME="screenshot_display_$(date +%Y-%m-%d_%H-%M-%S).png"
FILEPATH="$SCREENSHOT_DIR/$FILENAME"
grim -g "$(slurp -o)" "$FILEPATH"
if [ -f "$FILEPATH" ]; then
    wl-copy < "$FILEPATH"
    notify-send -i "$FILEPATH" "Display Screenshot" "Saved to $FILEPATH and copied to clipboard"
fi

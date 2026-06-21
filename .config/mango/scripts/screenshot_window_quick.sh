#!/bin/bash
SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"
FILENAME="screenshot_window_$(date +%Y-%m-%d_%H-%M-%S).png"
FILEPATH="$SCREENSHOT_DIR/$FILENAME"
GEOMETRY=$(slurp)
if [ -n "$GEOMETRY" ]; then
    grim -g "$GEOMETRY" "$FILEPATH"
    if [ -f "$FILEPATH" ]; then
        wl-copy < "$FILEPATH"
        notify-send -i "$FILEPATH" "Window Screenshot" "Saved to $FILEPATH and copied to clipboard"
    fi
else
    notify-send "Screenshot Cancelled" "No area selected"
fi

#!/bin/bash
# Screenshot selection (quick save + clipboard) - like macOS Cmd+Shift+4

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

FILENAME="screenshot_$(date +%Y-%m-%d_%H-%M-%S).png"
FILEPATH="$SCREENSHOT_DIR/$FILENAME"

# Capture selection and save
grim -g "$(slurp)" "$FILEPATH"

if [ -f "$FILEPATH" ]; then
    # Copy to clipboard
    wl-copy < "$FILEPATH"
    
    # Show notification with preview
    notify-send -i "$FILEPATH" "Screenshot Saved" "Saved to $FILEPATH and copied to clipboard"
else
    notify-send "Screenshot Cancelled" "No area selected"
fi

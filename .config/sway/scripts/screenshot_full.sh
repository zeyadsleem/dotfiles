#!/bin/bash
# Screenshot full display (quick save + clipboard) - like macOS Cmd+Shift+3

SCREENSHOT_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$SCREENSHOT_DIR"

FILENAME="screenshot_display_$(date +%Y-%m-%d_%H-%M-%S).png"
FILEPATH="$SCREENSHOT_DIR/$FILENAME"

# Get focused output
output_id=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused).name')

# Capture display
grim -o "$output_id" "$FILEPATH"

if [ -f "$FILEPATH" ]; then
    # Copy to clipboard
    wl-copy < "$FILEPATH"
    
    # Show notification with preview
    notify-send -i "$FILEPATH" "Display Screenshot" "Saved to $FILEPATH and copied to clipboard"
fi

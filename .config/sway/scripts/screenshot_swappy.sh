#!/bin/bash
MODE=$1
DEST="$HOME/Pictures/Screenshots"
mkdir -p "$DEST"
FILE="$DESTscreenshot_$(date +%Y%m%d_%H%M%S).png"
hyprshot -m "$MODE" -o "$FILE"
sleep 0.5
swaymsg exec "swappy -f $FILE"

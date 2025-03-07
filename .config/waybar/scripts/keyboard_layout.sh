#!/bin/bash

LAYOUT=$(swaymsg -t get_inputs -r | jq -r '.[] | select(.type == "keyboard") | .xkb_active_layout_name' | head -n1)
case "$LAYOUT" in
    "English (US)") echo "{\"text\": \"EN\", \"tooltip\": \"English (US)\"}" ;;
    "Arabic") echo "{\"text\": \"AR\", \"tooltip\": \"Arabic\"}" ;;
    *) echo "{\"text\": \"??\", \"tooltip\": \"Unknown\"}" ;;
esac

#!/bin/bash

layout=$(swaymsg -t get_inputs | jq -r '.[] | select(.type == "keyboard") | .xkb_active_layout_name' | head -n1)

case ${layout,,} in
"english") echo "🇺🇸 EN" ;;
"arabic") echo "🇸🇦 AR" ;;
*) echo "🌐 ${layout:0:2}" ;;
esac

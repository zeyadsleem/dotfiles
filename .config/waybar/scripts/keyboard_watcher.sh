#!/bin/bash
while true; do
    swaymsg -t subscribe '["input"]' | jq -r '.input.xkb_active_layout_name' | while read -r layout; do
        pkill -RTMIN+1 waybar
    done
done

#!/bin/sh
ydotool key 56:1 42:1 42:0 56:0
swayosd-client --input-source 2>/dev/null
pkill -RTMIN+1 waybar 2>/dev/null

#!/bin/sh
swaymsg input "type:keyboard" xkb_switch_layout next
pkill -RTMIN+1 waybar

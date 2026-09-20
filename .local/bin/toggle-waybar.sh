#!/bin/sh
if pgrep -x waybar >/dev/null 2>&1; then
    pkill -SIGUSR1 -x waybar
else
    niri msg action spawn -- waybar -c "$HOME/.config/waybar/config-niri"
fi

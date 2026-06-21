#!/usr/bin/env bash
# Mango autostart — runs once on startup via exec-once

# Polkit authentication agent
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# GNOME keyring
gnome-keyring-daemon --start --components=secrets,ssh &

# Kanshi (monitor management)
kanshi &

# Idle management
swayidle -w before-sleep "$HOME/.local/bin/lock-if-not-running.sh" &

# Desktop notifications
swaync &

# On-screen display for volume/brightness
swayosd-server &

# Clipboard history (text + images)
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

# Network applet
nm-applet --indicator &

sleep 2 && firewall-applet &

# App launcher drawer
nwg-drawer -r -term wezterm -c 6 -is 48 -mb 15 -ml 18 -mr 18 -mt 15 &

# ProtonVPN tray
protonvpn-app &

# Wallpaper (via Azote wrapper)
~/.azotebg &

wait

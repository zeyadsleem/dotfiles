#!/bin/sh

choice=$(printf 'Lock\nSuspend\nLogout\nReboot\nPoweroff\n' | fuzzel --dmenu --prompt='Power: ' --width=20 --lines=5)

case "$choice" in
  Lock)
    gtklock
    ;;
  Suspend)
    systemctl suspend
    ;;
  Logout)
    niri msg action quit --skip-confirmation
    ;;
  Reboot)
    systemctl reboot
    ;;
  Poweroff)
    systemctl poweroff
    ;;
esac

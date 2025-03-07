#!/bin/bash

SELECTION="$(printf "󰌾 Lock\n󰤄 Suspend\n󰍃 Log out\n Reboot\n Reboot to UEFI\n󰐥 Shutdown" | fuzzel --dmenu -a bottom-right -l 6 -w 18 -p "Select an option: ")"

confirm_action() {
    local action="$1"
    CONFIRMATION="$(printf "Yes\nNo" | fuzzel --dmenu -a bottom-right -l 2 -w 18 -p "$action?" --index 0)"
    [[ "$CONFIRMATION" == *"Yes"* ]]
}

case $SELECTION in
*"󰌾 Lock"*)
    gtklock
    ;;
*"󰤄 Suspend"*)
    if confirm_action "Suspend"; then
        systemctl suspend
    fi
    ;;
*"󰍃 Log out"*)
    if confirm_action "Log out"; then
        swaymsg exit
    fi
    ;;
*" Reboot"*)
    if confirm_action "Reboot"; then
        systemctl reboot
    fi
    ;;
*" Reboot to UEFI"*)
    if confirm_action "Reboot to UEFI"; then
        systemctl reboot --firmware-setup
    fi
    ;;
*"󰐥 Shutdown"*)
    if confirm_action "Shutdown"; then
        systemctl poweroff
    fi
    ;;
esac

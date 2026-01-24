#!/bin/bash

# Disable all wakeup devices
while read -r device _ status _; do
    if [[ $status == "*enabled" ]]; then
        echo "$device" | sudo tee /proc/acpi/wakeup >/dev/null
    fi
done </proc/acpi/wakeup

sleep 1

# Force suspend using sudo (now allowed without password)
sudo systemctl suspend
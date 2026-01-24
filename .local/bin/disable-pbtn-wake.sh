#!/bin/bash
# Check if PBTN is enabled in /proc/acpi/wakeup and disable it if so.
if grep -q "PBTN.*enabled" /proc/acpi/wakeup; then
    echo "Disabling PBTN wakeup..."
    echo PBTN > /proc/acpi/wakeup
else
    echo "PBTN wakeup already disabled."
fi

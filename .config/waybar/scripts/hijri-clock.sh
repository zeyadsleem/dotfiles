#!/bin/sh
# The Hijri date next to the clock, in Arabic.
#
# The date comes from the hijri script, which needs uv and a python package.
# When either is missing the module falls back to the Gregorian date, so it
# is never empty.
set -u

script="$HOME/.local/bin/hijri-date.py"
if [ -x "$script" ]; then
    out=$("$script" 2>/dev/null) && [ -n "$out" ] && {
        printf '%s\n' "$out"
        exit 0
    }
fi
date +%F

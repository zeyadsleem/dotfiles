#!/bin/sh
# The health dot of the bar.
#
# `dot health --json` prints exactly the three keys a waybar json custom
# module reads. When dot is missing or fails, the module still gets valid
# json, so the bar never renders an empty widget.
set -u

dot="$HOME/.local/bin/dot"
if [ -x "$dot" ]; then
    out=$("$dot" health --json 2>/dev/null) && [ -n "$out" ] && {
        printf '%s\n' "$out"
        exit 0
    }
fi
printf '%s\n' '{"text":"○","tooltip":"dot is not available","class":"bad"}'

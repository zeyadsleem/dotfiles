#!/bin/sh
# The health dot of the bar.
#
# `dot health --json` prints exactly the three keys a waybar json custom
# module reads. When dot is missing or prints nothing, the module still gets
# valid json, so the bar never renders an empty widget.
set -u

dot="$HOME/.local/bin/dot"
out=""
if [ -x "$dot" ]; then
    # `dot health` exits 1 when it finds a problem *and* prints the document
    # that explains it, so the exit status must not discard the output.
    out=$("$dot" health --json 2>/dev/null) || true
fi
if [ -n "$out" ]; then
    printf '%s\n' "$out"
    exit 0
fi
printf '%s\n' '{"text":"○","tooltip":"dot is not available","class":"bad"}'

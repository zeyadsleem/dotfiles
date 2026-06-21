#!/usr/bin/env bash
layout=$(/usr/bin/mmsg get keyboardlayout 2>/dev/null | /usr/bin/jq -r '.layout' 2>/dev/null)
if [ "$layout" = "ara" ]; then
    printf '{"text":"🇪🇬","alt":"ara"}\n'
elif [ "$layout" = "us" ]; then
    printf '{"text":"🇺🇸","alt":"us"}\n'
elif [ -n "$layout" ]; then
    printf '{"text":"%s","alt":"%s"}\n' "$layout" "$layout"
else
    printf '{"text":"us","alt":"us"}\n'
fi

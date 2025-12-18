#!/bin/bash

if ! pgrep -x "gtklock" >/dev/null; then
    gtklock -d
fi

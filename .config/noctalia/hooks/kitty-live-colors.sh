#!/usr/bin/env bash
set -euo pipefail

# Noctalia's colors_changed hook runs after the kitty template has rewritten
# themes/noctalia.conf. Push that palette into every live kitty instance so
# ANSI-index colors used by zsh, p10k, fzf and fast-syntax-highlighting follow
# the active theme without restarting the terminal or the shell.
theme_file="${XDG_CONFIG_HOME:-$HOME/.config}/kitty/themes/noctalia.conf"

[[ -r "$theme_file" ]] || exit 0
command -v kitty >/dev/null 2>&1 || exit 0

# kitty's `listen_on unix:/tmp/kitty` creates one socket per instance:
# /tmp/kitty-<pid>. Stale sockets are harmless: the command just fails for them.
shopt -s nullglob
sockets=(/tmp/kitty-*)
(( ${#sockets[@]} )) || exit 0

for socket in "${sockets[@]}"; do
  [[ -S "$socket" ]] || continue
  kitty @ --to "unix:${socket}" set-colors --all --configured "$theme_file" >/dev/null 2>&1 || true
done

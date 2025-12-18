#!/usr/bin/env bash

selected=$(cat ~/.config/tmux/.tmux-cht-languages ~/.config/tmux/.tmux-cht-command | fzf)
if [[ -z $selected ]]; then
  exit 0
fi

read -rp "Enter Query: " query

if grep -qs "$selected" ~/.config/tmux/.tmux-cht-languages; then
  query=$(echo "$query" | tr ' ' '+')
  tmux neww bash -c "curl -s cht.sh/$selected/$query | bat --paging=always --style=plain"
else
  tmux neww bash -c "curl -s cht.sh/$selected~$query | bat --paging=always --style=plain"
fi

#!/usr/bin/env bash

# Define the theme environment file
ENV_FILE="$HOME/.config/themes/current/zsh/env.zsh"

# Extract FZF_DEFAULT_OPTS value using zsh to handle multi-line and zsh-specific syntax
# Also override height to 100% and remove border for the popup context
if [ -f "$ENV_FILE" ]; then
    eval $(zsh -c "source \"$ENV_FILE\"; echo \"export FZF_DEFAULT_OPTS='\$FZF_DEFAULT_OPTS --height=100% --border=none'\"")
fi

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
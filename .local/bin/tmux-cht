#!/usr/bin/env bash

# Define the paths for the language and command files
LANG_FILE="$HOME/.config/tmux/.tmux-cht-languages"
CMD_FILE="$HOME/.config/tmux/.tmux-cht-command"

# Function to display error and exit
error_exit() {
  echo "Error: $1" >&2
  exit 1
}

# Check if required commands are available
command -v fzf >/dev/null 2>&1 || error_exit "fzf is not installed. Please install it first."
command -v curl >/dev/null 2>&1 || error_exit "curl is not installed. Please install it first."

# Check if the files exist
[[ -f "$LANG_FILE" ]] || error_exit "Language file not found: $LANG_FILE"
[[ -f "$CMD_FILE" ]] || error_exit "Command file not found: $CMD_FILE"

# Check if cht.sh is installed locally
if command -v cht.sh &>/dev/null; then
  use_local=true
else
  use_local=false
fi

# Use fzf to select from both files
selected=$(cat "$LANG_FILE" "$CMD_FILE" | fzf --prompt="Select language or command: " --header="Press CTRL-C to exit") || exit 0

# Exit if nothing was selected
[[ -z "$selected" ]] && exit 0

# Prompt for the query
read -p "Enter Query: " query

# Function to execute cht.sh query
execute_query() {
  local selected="$1"
  local query="$2"
  local use_local="$3"

  if $use_local; then
    if grep -q "^$selected$" "$LANG_FILE"; then
      cht.sh "$selected" "$query" | less -R
    else
      cht.sh "$selected" "$(echo $query | tr ' ' '+')" | less -R
    fi
  else
    if grep -q "^$selected$" "$LANG_FILE"; then
      curl -s "cht.sh/$selected/$query" | less -R
    else
      curl -s "cht.sh/$selected~$query" | less -R
    fi
  fi
}

# Process the query based on whether it's a language or a command
tmux neww bash -c "$(declare -f execute_query); execute_query '$selected' '$query' $use_local"

#!/usr/bin/env bash

# Define the theme environment file
ENV_FILE="$HOME/.config/themes/current/zsh/env.zsh"

# Load FZF colors from theme and force 100% height + no border
if [ -f "$ENV_FILE" ]; then
    eval $(zsh -c "source \"$ENV_FILE\"; echo \"export FZF_DEFAULT_OPTS='\$FZF_DEFAULT_OPTS --height=100% --border=none'\"")
fi

# Run the session wizard
exec ~/.tmux/plugins/tmux-session-wizard/bin/t

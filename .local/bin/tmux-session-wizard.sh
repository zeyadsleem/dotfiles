#!/usr/bin/env bash

# tmux popups inherit the tmux server's environment, which has no PATH of its own.
# Without this the wizard, fzf and zoxide are invisible inside the popup and it
# closes the instant it opens.
PATH="$HOME/.nix-profile/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:$PATH"
export PATH

# Define the theme environment file
ENV_FILE="$HOME/.config/themes/current/zsh/env.zsh"

# Load FZF colors from theme and force 100% height + no border
if [ -f "$ENV_FILE" ]; then
    eval $(zsh -c "source \"$ENV_FILE\"; echo \"export FZF_DEFAULT_OPTS='\$FZF_DEFAULT_OPTS --height=100% --border=none'\"")
fi

# Run the session wizard
exec "$HOME/.tmux/plugins/tmux-session-wizard/bin/t"

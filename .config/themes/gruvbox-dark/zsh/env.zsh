# FZF Configuration (Gruvbox Dark)
export FZF_DEFAULT_OPTS="
  --height 50%
  --layout=reverse
  --border=rounded
  --inline-info
  --multi
  --preview-window=right:60%:wrap:rounded:border-bold
  --bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview'
  --color=bg:#282828,bg+:#3c3836,fg:#ebdbb2,fg+:#ebdbb2,hl:#fe8019,hl+:#fe8019
  --color=info:#fe8019,prompt:#fe8019,pointer:#fe8019,marker:#fe8019,spinner:#fe8019,header:#ebdbb2
"

# FZF-Tab Settings
export FZF_DEFAULT_OPTS='--color=bg:#282828,fg:#ebdbb2'

# Colorls for Gruvbox Dark (using Dracula as base)
export LS_COLORS="$(vivid generate dracula 2>/dev/null || echo '')"
export DIR_COLORS="$LS_COLORS"

# Git Delta Theme
export DELTA_THEME="Monokai Extended"

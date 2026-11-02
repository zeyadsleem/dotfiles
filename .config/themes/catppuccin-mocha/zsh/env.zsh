# FZF Configuration (Catppuccin Mocha)
export FZF_DEFAULT_OPTS="
  --height 50%
  --layout=reverse
  --border=rounded
  --inline-info
  --multi
  --preview-window=right:60%:wrap:rounded:border-bold
  --bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview'
  --color=bg:#1e1e2e,bg+:#313244,fg:#cdd6f4,fg+:#cdd6f4,hl:#cba6f7,hl+:#cba6f7
  --color=info:#cba6f7,prompt:#cba6f7,pointer:#cba6f7,marker:#cba6f7,spinner:#cba6f7,header:#cdd6f4
"

# FZF-Tab Settings
export FZF_DEFAULT_OPTS='--color=bg:#1e1e2e,fg:#cdd6f4'

# Colorls for Catppuccin Mocha (using Dracula as base)
export LS_COLORS="$(vivid generate dracula 2>/dev/null || echo '')"
export DIR_COLORS="$LS_COLORS"

# Git Delta Theme
export DELTA_THEME="OneHalfDark"

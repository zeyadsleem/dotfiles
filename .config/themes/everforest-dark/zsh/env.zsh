# FZF Configuration (Everforest Dark)
export FZF_DEFAULT_OPTS="
  --height 50%
  --layout=reverse
  --border=rounded
  --inline-info
  --multi
  --preview-window=right:60%:wrap:rounded:border-bold
  --bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview'
  --color=bg:#2d353b,bg+:#343f44,fg:#d3c6aa,fg+:#d3c6aa,hl:#a7c080,hl+:#a7c080
  --color=info:#a7c080,prompt:#a7c080,pointer:#a7c080,marker:#a7c080,spinner:#a7c080,header:#d3c6aa
"

# FZF-Tab Settings
export FZF_DEFAULT_OPTS='--color=bg:#2d353b,fg:#d3c6aa'

# Colorls for Everforest Dark (using Dracula as base)
export LS_COLORS="$(vivid generate dracula 2>/dev/null || echo '')"
export DIR_COLORS="$LS_COLORS"

# Git Delta Theme
export DELTA_THEME="Nord"

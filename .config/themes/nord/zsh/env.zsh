# FZF Configuration (Nord)
export FZF_DEFAULT_OPTS="
  --height 50%
  --layout=reverse
  --border=rounded
  --inline-info
  --multi
  --preview-window=right:60%:wrap:rounded:border-bold
  --bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview'
  --color=bg:#2e3440,bg+:#3b4252,fg:#d8dee9,fg+:#d8dee9,hl:#88c0d0,hl+:#88c0d0
  --color=info:#88c0d0,prompt:#88c0d0,pointer:#88c0d0,marker:#88c0d0,spinner:#88c0d0,header:#d8dee9
"

# FZF-Tab Settings
export FZF_DEFAULT_OPTS='--color=bg:#2e3440,fg:#d8dee9'

# Colorls for Nord (using Dracula as base)
export LS_COLORS="$(vivid generate dracula 2>/dev/null || echo '')"
export DIR_COLORS="$LS_COLORS"

# Git Delta Theme
export DELTA_THEME="Nord"

# FZF Configuration (Dracula)
export FZF_DEFAULT_OPTS="
  --height 50%
  --layout=reverse
  --border=rounded
  --inline-info
  --multi
  --preview-window=right:60%:wrap:rounded:border-bold
  --bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview'
  --color=bg:#282a36,bg+:#44475a,fg:#f8f8f2,fg+:#f8f8f2,hl:#bd93f9,hl+:#bd93f9
  --color=info:#bd93f9,prompt:#bd93f9,pointer:#bd93f9,marker:#bd93f9,spinner:#bd93f9,header:#f8f8f2
"

# FZF-Tab Settings
export FZF_DEFAULT_OPTS='--color=bg:#282a36,fg:#f8f8f2'

# Colorls for Dracula (using Dracula as base)
export LS_COLORS="$(vivid generate dracula 2>/dev/null || echo '')"
export DIR_COLORS="$LS_COLORS"

# Git Delta Theme
export DELTA_THEME="Nord"

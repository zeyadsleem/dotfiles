# FZF Configuration (Tokyo Night)
export FZF_DEFAULT_OPTS="
  --height 50%
  --layout=reverse
  --border=rounded
  --inline-info
  --multi
  --preview-window=right:60%:wrap:rounded:border-bold
  --bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview'
  --color=bg:#1a1b26,bg+:#292e42,fg:#c0caf5,fg+:#c0caf5,hl:#7aa2f7,hl+:#7aa2f7
  --color=info:#7aa2f7,prompt:#7aa2f7,pointer:#7aa2f7,marker:#7aa2f7,spinner:#7aa2f7,header:#c0caf5
"

# FZF-Tab Settings
export FZF_DEFAULT_OPTS='--color=bg:#1a1b26,fg:#c0caf5'

# Colorls for Tokyo Night (using Dracula as base)
export LS_COLORS="$(vivid generate dracula 2>/dev/null || echo '')"
export DIR_COLORS="$LS_COLORS"

# Git Delta Theme
export DELTA_THEME="Nord"

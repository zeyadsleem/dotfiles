# FZF Configuration (Orchis Dark)
export FZF_DEFAULT_OPTS="
  --height 50%
  --layout=reverse
  --border=rounded
  --inline-info
  --multi
  --preview-window=right:60%:wrap:rounded:border-bold
  --bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview'
  --color=bg:#1e1e1e,bg+:#2e2e2e,fg:#dcdcdc,fg+:#ffffff,hl:#5294e2,hl+:#5294e2
  --color=info:#5294e2,prompt:#5294e2,pointer:#5294e2,marker:#5294e2,spinner:#5294e2,header:#dcdcdc
"

# FZF-Tab Settings
zstyle ':fzf-tab:*' fzf-flags --border=rounded --height=50% --preview-window=rounded:border-bold --color=bg:#1e1e1e,fg:#dcdcdc

# Colorls for Orchis Dark (using Dracula as base)
export LS_COLORS="$(vivid generate dracula 2>/dev/null || echo '')"
export DIR_COLORS="$LS_COLORS"

# Git Delta Theme
export DELTA_THEME="Dracula"

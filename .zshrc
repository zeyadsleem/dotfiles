# Powerlevel10k Instant Prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Locale settings for Arabic/UTF-8 support
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d $ZINIT_HOME ]]; then
  mkdir -p "${ZINIT_HOME:h}"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

# Theme Configuration
[[ -f ~/.config/themes/current/zsh/env.zsh ]] && source ~/.config/themes/current/zsh/env.zsh

if command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {}'"

export FZF_ALT_C_OPTS="--preview 'eza --tree --level=3 --color=always --icons --git {} | head -200'"

export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'
  --header 'Press CTRL-Y to copy command into clipboard'
  --color header:italic
"

# Load FZF bindings
if [ -f /usr/share/fzf/key-bindings.zsh ]; then
  source /usr/share/fzf/key-bindings.zsh
elif [ -f ~/.fzf/shell/key-bindings.zsh ]; then
  source ~/.fzf/shell/key-bindings.zsh
fi
if [ -f /usr/share/fzf/completion.zsh ]; then
  source /usr/share/fzf/completion.zsh
elif [ -f ~/.fzf/shell/completion.zsh ]; then
  source ~/.fzf/shell/completion.zsh
fi

# Plugins
zinit light zsh-users/zsh-completions
zinit light Aloxaf/fzf-tab
zinit light zsh-users/zsh-autosuggestions
zinit light zdharma-continuum/fast-syntax-highlighting
zinit light zsh-users/zsh-history-substring-search

# Syntax Highlighting Styles (Rose Pine Dawn)
typeset -A FAST_HIGHLIGHT_STYLES
FAST_HIGHLIGHT_STYLES[default]='none'
FAST_HIGHLIGHT_STYLES[unknown-token]='fg=#d7827e,bold'
FAST_HIGHLIGHT_STYLES[reserved-word]='fg=#7a5ccc,bold'
FAST_HIGHLIGHT_STYLES[alias]='fg=#286983'
FAST_HIGHLIGHT_STYLES[command]='fg=#286983,bold'
FAST_HIGHLIGHT_STYLES[path]='fg=#56949f,underline'
FAST_HIGHLIGHT_STYLES[globbing]='fg=#7a5ccc'
FAST_HIGHLIGHT_STYLES[option]='fg=#ea9d34'
FAST_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#56949f'
FAST_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#56949f'

# Completion System & FZF-Tab
autoload -Uz compinit
compinit
zinit cdreplay -q # Replay cached completions
zstyle ':completion:*' rehash true
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' menu no
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'


zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta --theme=Dracula'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word | delta --theme=Dracula'
zstyle ':fzf-tab:complete:(-command-|[^ ]*):*' fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:complete:(\|*/|)man:*' fzf-preview 'man $word'
zstyle ':fzf-tab:*' continuous-trigger '/'

# History
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
export HISTORY_IGNORE="(ls|clear|c|l|v|vim|nvim|exit)"
setopt PROMPT_SUBST AUTO_PARAM_SLASH AUTO_PARAM_KEYS INC_APPEND_HISTORY SHARE_HISTORY
setopt HIST_IGNORE_DUPS HIST_IGNORE_ALL_DUPS HIST_FIND_NO_DUPS HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS HIST_EXPIRE_DUPS_FIRST HIST_SAVE_NO_DUPS HIST_VERIFY

zshaddhistory() {
  emulate -L zsh
  [[ $1 != ${~HISTORY_IGNORE} ]]
}

export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# Fix Wayland Display inside tmux/sessions
if [[ -z "$WAYLAND_DISPLAY" ]]; then
  export WAYLAND_DISPLAY=$(ls $XDG_RUNTIME_DIR/wayland-* 2>/dev/null | grep -v ".lock" | head -n 1 | xargs basename 2>/dev/null)
fi

# =============================================================================
# Default Applications
# =============================================================================
export BROWSER="brave"
export TERMINAL="wezterm"

# =============================================================================
# Core Environment
# =============================================================================

# Shell Options
setopt AUTO_CD GLOB_DOTS COMPLETE_IN_WORD ALWAYS_TO_END EXTENDED_GLOB NO_BEEP INTERACTIVE_COMMENTS COMPLETE_ALIASES NO_FLOW_CONTROL
[[ -t 0 ]] && stty -ixon

# Powerlevel10k Theme
source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# External Tools
eval "$(zoxide init zsh)"
[[ -f ~/.env.zsh ]] && source ~/.env.zsh
[[ -f ~/.alias.zsh ]] && source ~/.alias.zsh

# Autosuggestions
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#9893a5'
ZSH_AUTOSUGGEST_HISTORY_IGNORE="$HISTORY_IGNORE"

# Keybindings
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down
bindkey -M emacs '^P' history-substring-search-up
bindkey -M emacs '^N' history-substring-search-down
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^H' backward-kill-word
bindkey '^?' backward-delete-char
bindkey '^[^?' backward-kill-word
bindkey '^/' undo
bindkey '^[/' redo
bindkey '^[[C' forward-char
bindkey '^ ' autosuggest-accept
bindkey '^f' autosuggest-accept

# PATH Configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/go/bin/:$PATH"
export PATH="$HOME/.jdks/openjdk-25.0.1/bin/:$PATH"

# Turso
export PATH="$PATH:/home/zeyad/.turso"

. "$HOME/.cargo/env"

# Automatically activate Python virtual environment
function auto_venv() {
  local venv_dirs=("venv" ".venv" "env")
  local found_venv=""

  for dir in "${venv_dirs[@]}"; do
    if [[ -d "$dir" && -f "$dir/bin/activate" ]]; then
      found_venv="$dir"
      break
    fi
  done

  if [[ -n "$found_venv" ]]; then
    # Activate if not already active or if it's a different one
    if [[ "$VIRTUAL_ENV" != "$PWD/$found_venv" ]]; then
      echo "Activating Python virtual environment: $found_venv"
      source "$found_venv/bin/activate"
    fi
  elif [[ -n "$VIRTUAL_ENV" ]]; then
    # Deactivate if we are no longer inside the project root of the active venv
    local venv_root="${VIRTUAL_ENV:h}"
    if [[ "$PWD" != "$venv_root"* ]]; then
        deactivate
    fi
  fi
}
add-zsh-hook chpwd auto_venv

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# pnpm
export PNPM_HOME="/home/zeyad/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# opencode
export PATH=/home/zeyad/.opencode/bin:$PATH

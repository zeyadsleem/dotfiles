# Powerlevel10k Instant Prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================================
# Locale / Arabic UTF-8 Support
# ============================================================

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US.UTF-8

setopt COMBINING_CHARS

# ============================================================
# Zsh Core Options
# ============================================================

setopt PROMPT_SUBST
setopt AUTO_CD
setopt GLOB_DOTS
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt EXTENDED_GLOB
setopt NO_BEEP
setopt INTERACTIVE_COMMENTS
setopt COMPLETE_ALIASES
setopt NO_FLOW_CONTROL
setopt AUTO_PARAM_SLASH
setopt AUTO_PARAM_KEYS

[[ -t 0 ]] && stty -ixon

# ============================================================
# Zinit
# ============================================================

ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "${ZINIT_HOME:h}"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

[[ -f "$ZINIT_HOME/zinit.zsh" ]] && source "$ZINIT_HOME/zinit.zsh"

# Theme Environment
[[ -f ~/.config/themes/current/zsh/env.zsh ]] && source ~/.config/themes/current/zsh/env.zsh

# ============================================================
# Core Environment
# ============================================================

export BROWSER="brave"
export TERMINAL="wezterm"
export EDITOR="nvim"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# ============================================================
# PATH Configuration — No Duplicates
# ============================================================

typeset -U path PATH

path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOME/go/bin"
  "$HOME/.jdks/openjdk-25.0.1/bin"
  "$HOME/.bun/bin"
  "$HOME/.config/herd-lite/bin"
  "$HOME/.turso"
  "$HOME/.local/share/mise/shims"
  $path
)

export PATH

# Rust
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# Vite+
[[ -f "$HOME/.vite-plus/env" ]] && source "$HOME/.vite-plus/env"

# ============================================================
# FZF Environment
# ============================================================

if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=3 --color=always --icons --git {} 2>/dev/null | head -200'"
export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | wl-copy)+abort'
  --header 'Press CTRL-Y to copy command into clipboard'
  --color header:italic
"

# ============================================================
# History Settings
# ============================================================

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

export HISTORY_IGNORE="(ls|clear|c|l|v|vim|nvim|exit)"

setopt INC_APPEND_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY

# setopt SHARE_HISTORY

zshaddhistory() {
  emulate -L zsh
  [[ $1 != ${~HISTORY_IGNORE} ]]
}

# ============================================================
# Wayland Fixes
# ============================================================

if [[ -z "$WAYLAND_DISPLAY" && -n "$XDG_RUNTIME_DIR" ]]; then
  for s in $XDG_RUNTIME_DIR/wayland-*(N); do
    [[ $s != *.lock ]] && export WAYLAND_DISPLAY=${s:t} && break
  done
fi

# ============================================================
# FZF Keybindings Only
# Important: don't load fzf completion.zsh with fzf-tab.
# ============================================================

if [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
elif [[ -r ~/.fzf/shell/key-bindings.zsh ]]; then
  source ~/.fzf/shell/key-bindings.zsh
fi

# ============================================================
# Completion System
# Main optimization:
# - compinit builds dump once.
# - later shells use compinit -C without expensive checks.
# ============================================================

zmodload zsh/complist
autoload -Uz compinit

ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p "$ZSH_CACHE_DIR"

ZCOMPDUMP="$ZSH_CACHE_DIR/.zcompdump-${HOST}-${ZSH_VERSION}"

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$ZSH_CACHE_DIR"
zstyle ':completion:*' rehash true
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' complete-options true
zstyle ':completion:*' verbose yes
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*:warnings' format 'No matches for: %d'
zstyle ':completion:*' menu no

if [[ -n "$LS_COLORS" ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

# Smarter fuzzy matching
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'r:|[._-]=* r:|=*' \
  'l:|=* r:|=*'

# Git completion behavior
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:git-switch:*' sort false
zstyle ':completion:*:git-branch:*' sort false

# Extra completion definitions before compinit
zinit ice lucid
zinit light zsh-users/zsh-completions

# Fast compinit
if [[ -s "$ZCOMPDUMP" ]]; then
  compinit -C -d "$ZCOMPDUMP"
else
  compinit -d "$ZCOMPDUMP"
fi

# Replay zinit completion hooks
zinit cdreplay -q

# Compile zcompdump in background for next startup
{
  if [[ -f "$ZCOMPDUMP" && ! "$ZCOMPDUMP.zwc" -nt "$ZCOMPDUMP" ]]; then
    zcompile "$ZCOMPDUMP"
  fi
} &!

# ============================================================
# Carapace Universal Completion — Cached
# Install: yay -S --needed carapace-bin
# ============================================================

if command -v carapace >/dev/null 2>&1; then
  export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'

  CARAPACE_CACHE="$ZSH_CACHE_DIR/carapace.zsh"

  if [[ ! -s "$CARAPACE_CACHE" || "$CARAPACE_CACHE" -ot "$(command -v carapace)" ]]; then
    carapace _carapace >| "$CARAPACE_CACHE"
  fi

  source "$CARAPACE_CACHE"
fi

# ============================================================
# fzf-tab
# Must be after compinit and before autosuggestions/highlighting.
# ============================================================

zinit ice lucid
zinit light Aloxaf/fzf-tab

zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':fzf-tab:*' fzf-flags --height=80% --layout=reverse --border

zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'eza -1 --color=always --icons "$realpath" 2>/dev/null || ls -la --color=always "$realpath" 2>/dev/null'

zstyle ':fzf-tab:complete:z:*' fzf-preview \
  'eza -1 --color=always --icons "$realpath" 2>/dev/null || ls -la --color=always "$realpath" 2>/dev/null'

zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps --pid=$word -o pid,ppid,cmd --no-headers -w -w'

zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview \
  'SYSTEMD_COLORS=1 systemctl status "$word" 2>/dev/null'

zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
  'git diff --color=always -- "$word" 2>/dev/null | ${commands[delta]:-cat}'

zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
  'git log --color=always "$word" 2>/dev/null'

zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
  'git show --color=always "$word" 2>/dev/null | ${commands[delta]:-cat}'

zstyle ':fzf-tab:complete:(\|*/|)man:*' fzf-preview \
  'MANWIDTH=80 man "$word" 2>/dev/null'

# ============================================================
# Autosuggestions Settings
# Loaded after first prompt for faster terminal startup.
# ============================================================

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=120
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#9893a5'
ZSH_AUTOSUGGEST_HISTORY_IGNORE="$HISTORY_IGNORE"

# Accept autosuggestion word by word with Ctrl + Right
autosuggest-forward-word() {
  if [[ -n $POSTDISPLAY ]]; then
    local suffix="$POSTDISPLAY"

    if [[ $suffix =~ ^([^[:space:]]+)([[:space:]]*)(.*) ]]; then
      local accept="${match[1]}${match[2]}"
      BUFFER+="$accept"
      CURSOR=$#BUFFER
      POSTDISPLAY="${match[3]}"
      zle -R
    fi
  else
    zle .forward-word
  fi
}

zle -N autosuggest-forward-word
ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=(autosuggest-forward-word)

zinit ice wait'0a' lucid atload'
  _zsh_autosuggest_start
  bindkey "^ " autosuggest-accept
  bindkey "^f" autosuggest-accept
  bindkey "^[[1;5C" autosuggest-forward-word
  (( $+functions[_zsh_autosuggest_bind_widgets] )) && _zsh_autosuggest_bind_widgets
'
zinit light zsh-users/zsh-autosuggestions

# ============================================================
# History Substring Search — Lazy
# ============================================================

zinit ice wait'0a' lucid atload'
  bindkey "^[[A" history-substring-search-up
  bindkey "^[[B" history-substring-search-down
  bindkey "^P" history-substring-search-up
  bindkey "^N" history-substring-search-down
  bindkey -M emacs "^P" history-substring-search-up
  bindkey -M emacs "^N" history-substring-search-down
'
zinit light zsh-users/zsh-history-substring-search

# ============================================================
# Syntax Highlighting Styles
# Loaded after first prompt to avoid startup delay.
# ============================================================

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

zinit ice wait'0a' lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# ============================================================
# Powerlevel10k Theme
# ============================================================

[[ -f ~/powerlevel10k/powerlevel10k.zsh-theme ]] && source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ============================================================
# External Tools Initialization
# ============================================================

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

[[ -f ~/.env.zsh ]] && source ~/.env.zsh
[[ -f ~/.alias.zsh ]] && source ~/.alias.zsh

# ============================================================
# Mise
# ============================================================

# أسرع وضع: shims موجودة في PATH فوق.
# لو احتجت auto-switch لكل مشروع، فعّل السطرين دول بدل الشيمز فقط:
#
# if [[ -x ~/.local/bin/mise ]]; then
#   eval "$(~/.local/bin/mise activate zsh)"
# elif command -v mise >/dev/null 2>&1; then
#   eval "$(mise activate zsh)"
# fi

# ============================================================
# Bun Lazy Wrapper
# ============================================================

bun() {
  unset -f bun
  [[ -s "/home/zeyad/.bun/_bun" ]] && source "/home/zeyad/.bun/_bun"
  /home/zeyad/.bun/bin/bun "$@"
}

# ============================================================
# General Keybindings
# ============================================================

bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5D' backward-word
bindkey '^H' backward-kill-word
bindkey '^?' backward-delete-char
bindkey '^[^?' backward-kill-word
bindkey '^/' undo
bindkey '^[/' redo
bindkey '^[[C' forward-char

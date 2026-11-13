# Powerlevel10k instant prompt (must stay near the top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Locale
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
setopt COMBINING_CHARS

# Core options
setopt PROMPT_SUBST
setopt AUTO_CD
setopt GLOB_DOTS
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt EXTENDED_GLOB
setopt NO_BEEP
setopt INTERACTIVE_COMMENTS
setopt NO_FLOW_CONTROL
setopt AUTO_PARAM_SLASH
setopt AUTO_PARAM_KEYS

[[ -t 0 ]] && stty -ixon
bindkey -e

# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "${ZINIT_HOME:h}"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
[[ -r "$ZINIT_HOME/zinit.zsh" ]] && source "$ZINIT_HOME/zinit.zsh"

# Environment
export BROWSER=brave
export TERMINAL=kitty
export EDITOR=nvim
export VISUAL=nvim
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT=-c

# PATH without duplicates
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOME/go/bin"
  "$HOME/.bun/bin"
  $path
)
export PATH

[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -r "$HOME/.vite-plus/env" ]] && source "$HOME/.vite-plus/env"
[[ -r ~/.env.zsh ]] && source ~/.env.zsh
[[ -r ~/.alias.zsh ]] && source ~/.alias.zsh

# FZF file and directory search
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=3 --color=always --icons --git {} 2>/dev/null | head -200'"

# FZF keybindings (Ctrl-T, Alt-C); Ctrl-R is rebound to the history widget below
if [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
elif [[ -r ~/.fzf/shell/key-bindings.zsh ]]; then
  source ~/.fzf/shell/key-bindings.zsh
fi

# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=100000
SAVEHIST=100000

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_LEX_WORDS
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_SAVE_NO_DUPS
setopt HIST_VERIFY

HISTORY_IGNORE='(ls|clear|x|c|l|v|vim|nvim|exit)'
zshaddhistory() {
  emulate -L zsh
  setopt extendedglob
  local line=${1%$'\n'}
  # ignored commands, single-key accidents, pasted escape junk
  [[ $line == ${~HISTORY_IGNORE} ]] && return 1
  [[ $line == *$'\e'* ]] && return 1
  (( ${#line} > 1 )) || return 1
  # a short word that is not a real command is a typo, not history
  if [[ $line == [[:alpha:]](#c1,3) ]] &&
    (( ! ${+commands[$line]} && ! ${+builtins[$line]} && ! ${+aliases[$line]} &&
       ! ${+functions[$line]} && ! ${+reswords[$line]} )); then
    return 1
  fi
  return 0
}

# Wayland fallback
if [[ -z "$WAYLAND_DISPLAY" && -n "$XDG_RUNTIME_DIR" ]]; then
  for socket in "$XDG_RUNTIME_DIR"/wayland-*(N); do
    [[ $socket != *.lock ]] && export WAYLAND_DISPLAY=${socket:t} && break
  done
fi

# Native Zsh completion + Arch zsh-completions
zmodload zsh/complist
autoload -Uz compinit

typeset -U fpath
[[ -d /usr/local/share/zsh/site-functions ]] && fpath=(/usr/local/share/zsh/site-functions $fpath)
[[ -d /usr/share/zsh/site-functions ]] && fpath=(/usr/share/zsh/site-functions $fpath)

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
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

[[ -n "$LS_COLORS" ]] && zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:git-switch:*' sort false
zstyle ':completion:*:git-branch:*' sort false

if [[ -s "$ZCOMPDUMP" && "$ZCOMPDUMP" -nt /usr/share/zsh/site-functions ]]; then
  compinit -C -d "$ZCOMPDUMP"
else
  compinit -d "$ZCOMPDUMP"
fi

if [[ -f "$ZCOMPDUMP" && ! -f "$ZCOMPDUMP.zwc" || "$ZCOMPDUMP" -nt "$ZCOMPDUMP.zwc" ]]; then
  zcompile "$ZCOMPDUMP" 2>/dev/null
fi

# fzf-tab: display native completion results
zinit ice lucid
zinit light Aloxaf/fzf-tab

zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' continuous-trigger '/'
zstyle ':fzf-tab:*' fzf-flags --height=80% --layout=reverse --border

zstyle ':fzf-tab:complete:cd:*' fzf-preview \
  'realpath=${realpath/#\~/$HOME}; eza -1 --color=always --icons "$realpath" 2>/dev/null || ls -la --color=always "$realpath" 2>/dev/null'

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

zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview \
  'MANWIDTH=80 man "$word" 2>/dev/null'

# Autosuggestions: history only, completion stays on Tab
ZSH_AUTOSUGGEST_STRATEGY=(history)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=120
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#9893a5'
ZSH_AUTOSUGGEST_HISTORY_IGNORE="$HISTORY_IGNORE"

zinit ice lucid atload'
  bindkey "^ " autosuggest-accept
  bindkey "^F" autosuggest-accept
'
zinit light zsh-users/zsh-autosuggestions

# Native prefix history search on Up/Down
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^P' up-line-or-beginning-search
bindkey '^N' down-line-or-beginning-search

# fzf widgets: Ctrl-R history, Tab on an empty line = commands, Tab twice = flags
if command -v fzf >/dev/null 2>&1; then
  typeset -ga __fzf_ui_opts=(
    --height=60%
    --layout=reverse
    --border=rounded
    --info=inline-right
    --no-hscroll
    --pointer='▶'
    --color=fg:246,hl:179,fg+:255,bg+:237,hl+:222,info:243,prompt:108,pointer:204,marker:114,spinner:108,header:240,border:239
  )

  # Ctrl-R: zsh history, newest first, exact duplicates removed
  typeset -ga __fzf_history_opts=(
    "${__fzf_ui_opts[@]}"
    --scheme=history
    --prompt='❯ '
    --preview='printf "%s\n" {}'
    --preview-window='down:4:wrap:border-top'
    --header='  ⏎ insert · ^C cancel'
  )

  __fzf_history_widget() {
    emulate -L zsh
    setopt localoptions pipefail noglob no_aliases
    local selected
    selected=$(
      fc -rl 1 | sed -E 's/^[[:space:]]*[0-9]+\*?[[:space:]]+//' | awk '!seen[$0]++' |
        fzf "${__fzf_history_opts[@]}"
    )
    if [[ -z $selected ]]; then
      zle reset-prompt
      return 0
    fi
    BUFFER=$selected
    CURSOR=${#BUFFER}
    zle reset-prompt
  }
  zle -N __fzf_history_widget
  bindkey '^R' __fzf_history_widget

  # Tab on an empty line: every command, function and alias this shell knows
  typeset -ga __fzf_command_opts=(
    "${__fzf_ui_opts[@]}"
    --prompt='cmd ❯ '
    --preview='whence -w {} 2>/dev/null; whatis {} 2>/dev/null | head -2'
    --preview-window='down:3:wrap:border-top'
    --header='  ⏎ insert · ^C cancel'
  )

  __fzf_command_widget() {
    emulate -L zsh
    setopt localoptions pipefail noglob no_aliases
    local selected name
    local -a names
    names=( "${(@k)commands}" "${(@k)builtins}" "${(@k)reswords}" "${(@k)functions}" )
    for name in "${(@k)aliases}"; do
      (( ${+galiases[$name]} )) || names+=( "$name" )
    done
    selected=$(
      print -rl -- "${(@)names}" | grep -vE '^[._]' | sort -u | fzf "${__fzf_command_opts[@]}"
    )
    if [[ -z $selected ]]; then
      zle reset-prompt
      return 0
    fi
    BUFFER=$selected
    CURSOR=${#BUFFER}
    zle reset-prompt
  }

  # Tab inside the completion popup asks for the command's own options
  typeset -g __fzf_tab_flag="${XDG_RUNTIME_DIR:-/tmp}/fzf-tab-want-flags"
  zstyle ':fzf-tab:*' fzf-bindings "tab:execute-silent(: > ${__fzf_tab_flag})+abort"

  __fzf_options_widget() {
    local before=$BUFFER
    LBUFFER+='-'
    zle fzf-tab-complete
    if [[ $BUFFER == "$before-" ]]; then
      BUFFER=$before
      CURSOR=${#BUFFER}
      zle reset-prompt
    fi
  }

  __tab_complete() {
    if [[ -z ${BUFFER//[[:space:]]/} ]]; then
      __fzf_command_widget
      return 0
    fi
    rm -f -- "$__fzf_tab_flag"
    zle fzf-tab-complete
    if [[ -e $__fzf_tab_flag ]]; then
      rm -f -- "$__fzf_tab_flag"
      __fzf_options_widget
    fi
  }
  zle -N __tab_complete
  bindkey '^I' __tab_complete
else
  bindkey '^R' history-incremental-search-backward
fi

# zoxide
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"

  # `cd ara<TAB>` completes from the zoxide database; path-like input keeps normal completion
  __cd_zoxide_complete() {
    local prefix=${(Q)words[CURRENT]}

    if [[ -z $prefix || $prefix == [-+.~]* || $prefix == */* ]]; then
      _cd
      return
    fi

    local -a matches display
    matches=(${(f)"$(zoxide query --list -- "$prefix" 2>/dev/null)"})
    if (( ! $#matches )); then
      _cd
      return
    fi

    local dir
    for dir in $matches; do
      if [[ $dir == $HOME/* ]]; then
        display+=("~/${(q)${dir#$HOME/}}")
      else
        display+=("${(q)dir}")
      fi
    done
    compadd -U -Q -- $display
  }
  compdef __cd_zoxide_complete cd
fi

# Powerlevel10k
[[ -r ~/powerlevel10k/powerlevel10k.zsh-theme ]] && source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh

# Syntax highlighting must load last
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

zinit ice lucid
zinit light zdharma-continuum/fast-syntax-highlighting

# General keybindings
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5D' backward-word
bindkey '^[[1;5C' forward-word
bindkey '^H' backward-kill-word
bindkey '^?' backward-delete-char
bindkey '^[^?' backward-kill-word
bindkey '^/' undo
bindkey '^[/' redo
bindkey '^[[C' forward-char

# pnpm
export PNPM_HOME="/home/zeyad/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end

# opencode
export PATH=/home/zeyad/.opencode/bin:$PATH

# Hermes Agent command
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) export PATH="$HOME/.local/bin:$PATH" ;; esac

# ApexYard: enable Claude Code LSP (added by /setup)
export ENABLE_LSP_TOOL=1

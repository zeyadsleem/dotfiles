# Powerlevel10k instant prompt (must stay near the top)
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ------------------------------------------------------------------------------
# Locale & core options
# ------------------------------------------------------------------------------
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
setopt COMBINING_CHARS

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

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------
export BROWSER=helium-browser
export TERMINAL=kitty
export EDITOR=nvim
export VISUAL=nvim
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT=-c

# PATH (deduped). Keep user/tool bins early; append tool-specific paths once.
typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/bin"
  "$HOME/go/bin"
  "$HOME/.bun/bin"
  "$HOME/.opencode/bin"
  $path
)
[[ -n "${PNPM_HOME:-}" ]] || export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) path+=("$PNPM_HOME") ;;
esac
export PATH

[[ -r "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -r "$HOME/.vite-plus/env" ]] && source "$HOME/.vite-plus/env"
[[ -r ~/.env.zsh ]] && source ~/.env.zsh

# ------------------------------------------------------------------------------
# Plugins (manual sourcing for fast startup; no Zinit loader overhead)
# Refresh with `zsh-plugins-update`.
# ------------------------------------------------------------------------------
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/plugins"
zsh-plugins-update() {
  local plugin
  for plugin in Aloxaf---fzf-tab zsh-users---zsh-autosuggestions zdharma-continuum---fast-syntax-highlighting; do
    git -C "$ZSH_PLUGIN_DIR/$plugin" pull --ff-only
  done
}

# ------------------------------------------------------------------------------
# History
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Wayland fallback
# ------------------------------------------------------------------------------
if [[ -z "$WAYLAND_DISPLAY" && -n "$XDG_RUNTIME_DIR" ]]; then
  for socket in "$XDG_RUNTIME_DIR"/wayland-*(N); do
    [[ $socket != *.lock ]] && export WAYLAND_DISPLAY=${socket:t} && break
  done
fi

# ------------------------------------------------------------------------------
# Completion (native compinit + fzf-tab)
# ------------------------------------------------------------------------------
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

if [[ -f "$ZCOMPDUMP" && ( ! -f "$ZCOMPDUMP.zwc" || "$ZCOMPDUMP" -nt "$ZCOMPDUMP.zwc" ) ]]; then
  zcompile "$ZCOMPDUMP" 2>/dev/null
fi

# fzf-tab: display native completion results
[[ -r "$ZSH_PLUGIN_DIR/Aloxaf---fzf-tab/fzf-tab.plugin.zsh" ]] && \
  source "$ZSH_PLUGIN_DIR/Aloxaf---fzf-tab/fzf-tab.plugin.zsh"

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

# ------------------------------------------------------------------------------
# FZF (file search + widgets)
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Autosuggestions
# ------------------------------------------------------------------------------
ZSH_AUTOSUGGEST_STRATEGY=(history)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=120
# ANSI palette index: Kitty's live palette is pushed on Noctalia colors_changed.
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_HISTORY_IGNORE="$HISTORY_IGNORE"

[[ -r "$ZSH_PLUGIN_DIR/zsh-users---zsh-autosuggestions/zsh-autosuggestions.plugin.zsh" ]] && \
  source "$ZSH_PLUGIN_DIR/zsh-users---zsh-autosuggestions/zsh-autosuggestions.plugin.zsh"
bindkey "^ " autosuggest-accept
bindkey "^F" autosuggest-accept

# ------------------------------------------------------------------------------
# History search & custom widgets
# ------------------------------------------------------------------------------
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
    # ANSI 0-15 track Kitty's Noctalia-driven palette; -1 keeps terminal defaults.
    --color=fg:-1,hl:3,fg+:-1,bg+:0,hl+:11,info:8,prompt:6,pointer:5,marker:2,spinner:6,header:8,border:0
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

# ------------------------------------------------------------------------------
# zoxide
# ------------------------------------------------------------------------------
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

# ------------------------------------------------------------------------------
# Aliases & functions
# ------------------------------------------------------------------------------

# Safety
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

md() { mkdir -p "$@" && cd "${@: -1}"; }
alias du='du -h'

# Prefer zoxide for directory jumps; keep builtin cd fallback.
cd() {
  if command -v zoxide >/dev/null 2>&1; then
    z "$@"
  else
    builtin cd "$@"
  fi
}

alias x=exit
alias o='opencode'

# File listing
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -la --icons --git --group-directories-first'
  alias l='eza -a --icons --group-directories-first'
  alias lt='eza -la --icons --tree --level=4 --ignore-glob="**/node_modules|**/.git"'
fi
command -v bat >/dev/null 2>&1 && alias cat='bat --style=plain'

# Git
git_branch() { git rev-parse --abbrev-ref HEAD; }
alias clone='git clone'
alias fetch='git fetch && git status -s'
alias pull='git pull && git status -s'
alias push='git push'
pushupstream() { git push --set-upstream origin "$(git_branch)"; }
commit() { git commit -a -m "$*"; }
alias amend='git commit --amend'
alias amendall='git commit --amend --no-edit --allow-empty --allow-empty-message '
alias br='git branch -vv'
alias co='git checkout'
alias trackedbranch='git rev-parse --abbrev-ref --symbolic-full-name @{u}'

st() {
  git status | sed -n '/Your/,/^$/p'
  git status -s
  echo
  git log --pretty=format:"%h - <%an> %s (%cr)" --date=relative -3
  echo
}

log() { git log --pretty=format:"%h - <%an> %s (%cr)" --date=relative -10 "$@"; }
alias mylog='git log --pretty=format:"%h - <%an> %s (%cr)" --date=relative -10 --author=zeyad.sleem'
alias stash='git stash push'
alias unstash='git stash pop'
alias stashes='git stash list'
alias clean='git clean -xdf'
alias unstage='git reset HEAD'
alias pick='git cherry-pick'
alias rebasemain='git fetch && git rebase origin/main && git status -s'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
odd() { git difftool -y -d "$1".."$2"; }

# Herdr
alias h='herdr'
alias hs='herdr session attach shell'
alias hc='herdr session attach code'

# Development tools
alias v='nvim'
alias pn='pnpm'
alias dlx='pnpm dlx'
alias pni='pnpm install'
alias pna='pnpm add'
alias pnr='pnpm run'
alias pnu='pnpm update'

# AI helpers
# gpt: one-shot OpenCode question on the free Big Pickle model.
# Usage: gpt <question...> | gpt -c <follow up> | gpt -m provider/model ...
gpt() {
  if (( $# == 0 )); then
    print -u2 "usage: gpt [-c] [-m provider/model] <question...>"
    return 1
  fi

  local arg has_model=0
  for arg in "$@"; do
    [[ $arg == -m || $arg == --model || $arg == --model=* ]] && has_model=1
  done

  if (( has_model )); then
    opencode run "$@"
  else
    opencode run -m opencode/big-pickle "$@"
  fi
}

# img: free pollinations.ai image generation (no API key required).
# Usage: img [-s WxH] [-o file] [-n] [-f] <prompt...>
img() {
  local size="1024x1024" out="" no_open=0 force=0 width height prompt=""
  local dir="$HOME/Pictures/ai"
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/img"

  while (( $# )); do
    case $1 in
      -s)
        [[ -n ${2:-} && $2 =~ ^[0-9]+x[0-9]+$ ]] || { print -u2 "img: -s takes WxH, got '${2:-}'"; return 1; }
        size="$2"; shift 2 ;;
      -o)
        [[ -n ${2:-} ]] || { print -u2 "img: -o needs a file path"; return 1; }
        out="$2"; shift 2 ;;
      -n) no_open=1; shift ;;
      -f|--force) force=1; shift ;;
      -h|--help) print -u2 "usage: img [-s WxH] [-o file] [-n] [-f] <prompt...>"; return 0 ;;
      --) shift; break ;;
      -*) print -u2 "img: unknown option '$1'"; return 1 ;;
      *) break ;;
    esac
  done

  prompt="$*"
  if [[ -z ${prompt//[[:space:]]/} ]]; then
    print -u2 "usage: img [-s WxH] [-o file] [-n] [-f] <prompt...>"
    return 1
  fi

  width="${size%x*}"
  height="${size#*x}"

  if [[ -z $out ]]; then
    mkdir -p "$dir" || return 1
    out="$dir/$(date +%Y%m%d-%H%M%S).jpg"
  fi

  local encoded
  encoded="$(printf '%s' "$prompt" | jq -sRr '@uri')" || {
    print -u2 "img: jq is required to encode the prompt"
    return 1
  }

  mkdir -p "$cache" || return 1
  local key cached
  key="$(printf '%s|%s' "$prompt" "$size" | sha1sum | cut -d' ' -f1)"
  cached="$cache/$key.jpg"

  if (( ! force )) && [[ -s $cached && $(file -b --mime-type "$cached" 2>/dev/null) == image/* ]]; then
    cp -f "$cached" "$out" || return 1
    print -u2 "img: cached -> $out"
    print "$out"
    (( no_open )) || gio open "$out" >/dev/null 2>&1
    return 0
  fi

  local url="https://image.pollinations.ai/prompt/${encoded}?width=${width}&height=${height}&nologo=true"
  local -a auth=()
  [[ -n ${POLLINATIONS_TOKEN:-} ]] && auth=(-H "Authorization: Bearer $POLLINATIONS_TOKEN")

  print -u2 "generating ${width}x${height} -> $out"

  local attempt=1 max_attempts=3 ok=0 message pause tmp
  tmp="$(mktemp "${TMPDIR:-/tmp}/img.XXXXXX")" || return 1

  while (( attempt <= max_attempts )); do
    curl -sS -L --max-time 180 "${auth[@]}" -o "$tmp" "$url" 2>/dev/null
    if [[ -s $tmp ]] && [[ $(file -b --mime-type "$tmp" 2>/dev/null) == image/* ]]; then
      ok=1
      break
    fi

    message="$(jq -r '.error.message // empty' "$tmp" 2>/dev/null)"
    : >"$tmp"
    print -u2 "img: ${message:-no image returned} (attempt $attempt/$max_attempts)"

    if (( attempt < max_attempts )); then
      pause="$(printf '%s' "$message" | grep -oiE 'after [0-9]+ ?s' | grep -oE '[0-9]+' | head -1)"
      pause="${pause:-8}"
      (( pause > 70 )) && pause=70
      print -u2 "img: waiting ${pause}s"
      sleep "$pause"
    fi
    (( attempt++ ))
  done

  if (( ! ok )); then
    rm -f "$tmp"
    print -u2 "img: gave up after $max_attempts attempts."
    print -u2 "img: the free tier allows 1 image per 45s per IP and the shared API is often busy."
    print -u2 "img: try again in a minute, or set POLLINATIONS_TOKEN to lift the limit."
    return 1
  fi

  mv -f "$tmp" "$out" || { rm -f "$tmp"; print -u2 "img: cannot write $out"; return 1; }
  cp -f "$out" "$cached" 2>/dev/null

  print "$out"
  (( no_open )) || gio open "$out" >/dev/null 2>&1
}

# System utilities
alias open='gio open'
alias c='clear'
alias wp='noctalia msg panel-toggle wallpaper'

if command -v systemctl >/dev/null 2>&1; then
  alias sctl='sudo systemctl'
  alias jctl='sudo journalctl'
fi

# Nix helpers (edit the declarative packages list and re-activate HM)
nxin() {
  local pkg="$1"
  local file="$HOME/dotfiles/nix/modules/packages.nix"

  if [[ -z "$pkg" ]]; then
    echo "usage: nxin <nix-package-name>"
    return 1
  fi
  if [[ ! "$pkg" =~ ^[a-zA-Z0-9._+-]+$ ]]; then
    echo "error: invalid package name '$pkg'"
    return 1
  fi
  if [[ ! -f "$file" ]]; then
    echo "error: packages.nix not found at $file"
    return 1
  fi
  if grep -qE "^[[:space:]]*${pkg}[[:space:]]*$" "$file"; then
    echo "'$pkg' is already in packages.nix"
    return 0
  fi

  sed -i "0,/^[[:space:]]*\];$/s//    ${pkg}\n  ];/" "$file"
  echo "added '$pkg' to packages.nix - re-activating Home Manager..."
  (cd "$HOME/dotfiles" && nix run home-manager/master -- switch --flake '.#zeyad')
}

nxrm() {
  local pkg="$1"
  local file="$HOME/dotfiles/nix/modules/packages.nix"

  if [[ -z "$pkg" ]]; then
    echo "usage: nxrm <nix-package-name>"
    return 1
  fi
  if [[ ! "$pkg" =~ ^[a-zA-Z0-9._+-]+$ ]]; then
    echo "error: invalid package name '$pkg'"
    return 1
  fi
  if [[ ! -f "$file" ]]; then
    echo "error: packages.nix not found at $file"
    return 1
  fi
  if ! grep -qE "^[[:space:]]*${pkg}[[:space:]]*$" "$file"; then
    echo "'$pkg' is not in packages.nix"
    return 1
  fi

  sed -i "/^[[:space:]]*${pkg}[[:space:]]*$/d" "$file"
  echo "removed '$pkg' from packages.nix - re-activating Home Manager..."
  (cd "$HOME/dotfiles" && nix run home-manager/master -- switch --flake '.#zeyad')
}

# Utilities
lg() {
  export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
  lazygit "$@"
  if [[ -f $LAZYGIT_NEW_DIR_FILE ]]; then
    cd "$(cat "$LAZYGIT_NEW_DIR_FILE")" || return
    rm -f -- "$LAZYGIT_NEW_DIR_FILE"
  fi
}

yy() {
  local tmp
  tmp="$(mktemp -t yazi-cwd.XXXXXX)" || return 1
  yazi "$@" --cwd-file="$tmp"
  if [[ -s $tmp ]]; then
    cd "$(cat "$tmp")" || return
  fi
  rm -f -- "$tmp"
}

fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  [[ -n $pid ]] && echo "$pid" | xargs kill -"${1:-15}"
}

bak() { cp "$1"{,.bak.$(date +%Y%m%d_%H%M%S)}; }

extract() {
  [[ ! -f $1 ]] && return 1
  case $1 in
    *.tar.bz2) tar xjf "$1" ;;
    *.tar.gz)  tar xzf "$1" ;;
    *.tar.xz)  tar xJf "$1" ;;
    *.bz2)     bunzip2 "$1" ;;
    *.gz)      gunzip "$1" ;;
    *.tar)     tar xf "$1" ;;
    *.zip)     unzip "$1" ;;
    *.7z)      7z x "$1" ;;
    *.rar)     unrar x "$1" ;;
    *)         echo "Unknown archive format"; return 1 ;;
  esac
}

topcmd() {
  history | awk '{CMD[$2]++} END {for (a in CMD) print CMD[a], a}' | sort -nr | head -20
}

pnpm-auto() {
  if [[ -f package.json ]]; then
    local node_version
    node_version=$(node -p "require('./package.json').engines?.node || '24.13.0'")
    pnpm env use "$node_version"
  fi
}

# Zsh suffix/global aliases and named directories
alias -s {txt,yml,yaml,toml,lua,conf,ini}=nvim
alias -s {go,js,ts,py,c,cpp,h,hpp,css,html}=nvim
alias -s json=jless
alias -s md='glow -p'

alias -g NE='2> /dev/null'
alias -g NO='&> /dev/null'
alias -g G='| grep'
alias -g C='| wl-copy'

hash -d dotfiles=$HOME/dotfiles
hash -d conf=$HOME/.config

# ------------------------------------------------------------------------------
# Prompt (git info line + p10k active prompt)
# ------------------------------------------------------------------------------
# Suppress the default inverse `%` end-of-prompt marker on the handoff to p10k.
PROMPT_EOL_MARK=''

# Two-line prompt look with a ONE-line active prompt. `_print_git_info_line`
# writes dir/git/worktree as ordinary output in precmd, so zsh's active prompt
# remains one logical line and Herdr pane splits never duplicate it. It is
# synchronous, so git/worktree info is complete before the prompt is drawn.
_print_git_info_line() {
  emulate -L zsh
  local out head branch ab='' ahead='' behind='' flags='' worktree='' color=2
  local -a lines

  out=$(command git --no-optional-locks status --porcelain=v1 -b --untracked-files=normal 2>/dev/null) || return 0
  lines=(${(f)out})

  head=${lines[1]#\#\# }
  branch=${head%% *}
  branch=${branch%%...*}
  if [[ $head == *'['* ]]; then
    ab=${head##*\[}
    ab=${ab%%\]*}
    [[ $ab == *ahead* ]] && ahead="↑${${ab#*ahead }%%,*}"
    [[ $ab == *behind* ]] && behind="↓${ab##*behind }"
  fi
  if [[ $branch == HEAD ]]; then
    branch=$(command git rev-parse --short HEAD 2>/dev/null) || branch='detached'
  fi

  local line x y
  for line in ${lines[2,-1]}; do
    [[ -z $line ]] && continue
    x=${line[1]}
    y=${line[2]}
    case $x in
      '?'|'!') flags+='?' ;;
      M|A|D|R|C) flags+='+' ;;
    esac
    case $y in
      M|D|R|C) flags+='*' ;;
    esac
  done
  [[ -n $flags ]] && color=3

  local dirs gd gc
  dirs=$(command git rev-parse --git-dir --git-common-dir 2>/dev/null) || dirs=''
  if [[ -n $dirs ]]; then
    gd=${dirs%%$'\n'*}
    gc=${dirs##*$'\n'}
    [[ $gd != $gc ]] && worktree=" %F{6}wt:${gd:t}%f"
  fi

  local markers=''
  [[ -n $flags ]] && markers=" %F{1}${flags}%f"
  local delta=''
  [[ -n $ahead$behind ]] && delta=" %F{5}${ahead}${behind}%f"

  print -rP -- "%F{4}%~%f  %F{${color}} ${branch}%f${delta}${worktree}${markers}"
}

# p10k forces `_p9k_precmd` to the end; this hook stays before it so the info
# line is printed before the prompt is drawn.
autoload -Uz add-zsh-hook
add-zsh-hook precmd _print_git_info_line

# Powerlevel10k
[[ -r ~/powerlevel10k/powerlevel10k.zsh-theme ]] && source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ -r ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ------------------------------------------------------------------------------
# Syntax highlighting (must load last)
# ------------------------------------------------------------------------------
typeset -A FAST_HIGHLIGHT_STYLES
# ANSI palette indices (0-15) follow Kitty's Noctalia-driven palette live.
FAST_HIGHLIGHT_STYLES[default]='none'
FAST_HIGHLIGHT_STYLES[unknown-token]='fg=1,bold'
FAST_HIGHLIGHT_STYLES[reserved-word]='fg=5,bold'
FAST_HIGHLIGHT_STYLES[alias]='fg=6'
FAST_HIGHLIGHT_STYLES[command]='fg=4,bold'
FAST_HIGHLIGHT_STYLES[path]='fg=6,underline'
FAST_HIGHLIGHT_STYLES[globbing]='fg=5'
FAST_HIGHLIGHT_STYLES[option]='fg=3'
FAST_HIGHLIGHT_STYLES[single-quoted-argument]='fg=2'
FAST_HIGHLIGHT_STYLES[double-quoted-argument]='fg=2'

[[ -r "$ZSH_PLUGIN_DIR/zdharma-continuum---fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] && \
  source "$ZSH_PLUGIN_DIR/zdharma-continuum---fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# ------------------------------------------------------------------------------
# Keybindings
# ------------------------------------------------------------------------------
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

# Environment toggles
export ENABLE_LSP_TOOL=1

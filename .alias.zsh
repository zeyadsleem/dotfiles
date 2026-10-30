#!/usr/bin/env bash
# Shell Configuration - Aliases & Functions

# SAFETY - Prevent Accidental File Operations
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# NAVIGATION - Directory Movement
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

function md() {
    mkdir -p "$@" && cd "${@: -1}"
}

alias du='du -h'
function cd() {
    if command -v zoxide &> /dev/null; then
        z "$@"
    else
        builtin cd "$@"
    fi
}

alias x=exit
alias o='opencode'

# FILE LISTING - Enhanced with eza/bat
command -v eza &>/dev/null && {
    alias ls='eza -la --icons --git --group-directories-first'
    alias l='eza -a --icons --group-directories-first'
    alias lt='eza -la --icons --tree --level=4 --ignore-glob="**/node_modules|**/.git"'
}

command -v bat &>/dev/null && alias cat='bat --style=plain'

# GIT - Version Control Shortcuts
# Helper Functions
function git_branch() {
    git rev-parse --abbrev-ref HEAD
}

# Basic Operations
alias clone='git clone'
alias fetch='git fetch && git status -s'
alias pull='git pull && git status -s'
alias push='git push'

function pushupstream() {
    git push --set-upstream origin $(git_branch)
}

# Staging & Committing
function commit() {
    git commit -a -m "$*"
}

alias amend='git commit --amend'
alias amendall='git commit --amend --no-edit --allow-empty --allow-empty-message '

# Branching & Checkout
alias br='git branch -vv'
alias co='git checkout'
alias trackedbranch='git rev-parse --abbrev-ref --symbolic-full-name @{u}'

# Status & Logging
function st() {
    git status | sed -n '/Your/,/^$/p'
    git status -s
    echo
    git log --pretty=format:"%h - <%an> %s (%cr)" --date=relative -3
    echo
}

function log() {
    git log --pretty=format:"%h - <%an> %s (%cr)" --date=relative -10 "$@"
}

alias mylog='git log --pretty=format:"%h - <%an> %s (%cr)" --date=relative -10 --author=zeyad.sleem'

# Stashing
alias stash='git stash push'
alias unstash='git stash pop'
alias stashes='git stash list'

# Advanced Operations
alias clean='git clean -xdf'
alias unstage='git reset HEAD'
alias pick='git cherry-pick'
alias rebasemain='git fetch && git rebase origin/main && git status -s'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'

function odd() {
    git difftool -y -d "$1".."$2"
}

# KUBERNETES - Container Orchestration
# alias k='kubectl'
# alias kget='kubectl get'
# alias kdesc='kubectl describe'
# alias klog='kubectl logs'
# alias kall='kubectl get all'
# alias kpod='kubectl get pod'
# alias kdel='kubectl delete pod'
# alias kx='kubectx'
# alias kn='kubens'

# function ksecret() {
#     kubectl get secret "$@" -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{"\n"}}{{end}}'
# }
# 
# function kexec() {
#     local pod="$1"
#     local container="$2"
#     if [ -z "$container" ]; then
#         kubectl exec -it "$pod" -- /bin/bash
#     else
#         kubectl exec -it "$pod" -c "$container" -- /bin/bash
#     fi
# }

# TMUX - Terminal Multiplexer
alias t='tmux'
alias ta='tmux attach'

# DEVELOPMENT TOOLS
alias v='nvim'        # Neovim editor
alias pn="pnpm"
alias dlx='pnpm dlx'       # Execute pnpm packages
alias pni="pnpm install"
alias pna="pnpm add"
alias pnr="pnpm run"
alias pnu="pnpm update"

# Docker
# alias docker='podman'
# alias docker-compose='podman-compose'

# AI - one-shot questions on OpenCode's free Big Pickle model
# Usage: gpt <question...>          new session
#        gpt -c <follow up>         continue the last session
#        gpt -m provider/model ...  override the model
function gpt() {
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

# AI image generation - free pollinations.ai backend (the one tgpt uses), no API key
# Usage: img <prompt...>          saves to ~/Pictures/ai and opens it
#        img -s 512x512 <prompt>  size
#        img -o out.jpg <prompt>  output path
#        img -n <prompt>          save without opening
function img() {
    local size="1024x1024" out="" no_open=0 force=0 width height prompt=""
    local dir="$HOME/Pictures/ai"
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/img"

    while (( $# )); do
        case $1 in
            -s) [[ -n ${2:-} && $2 =~ ^[0-9]+x[0-9]+$ ]] || { print -u2 "img: -s takes WxH, got '${2:-}'"; return 1 }; size="$2"; shift 2 ;;
            -o) [[ -n ${2:-} ]] || { print -u2 "img: -o needs a file path"; return 1 }; out="$2"; shift 2 ;;
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

# SYSTEM UTILITIES
alias open='gio open'
alias c='clear'

# WALLPAPER - Set desktop background (persists across reboots)
alias wp='set-wallpaper'

if command -v systemctl &>/dev/null; then
    alias sctl='sudo systemctl'
    alias jctl='sudo journalctl'
fi

# NIX - Declarative package management
# nxin <pkg> adds the package to home.packages (nix/modules/packages.nix) and
# re-activates Home Manager, so the tool lands on PATH and is persisted across
# machines. Use the Nix package name (e.g. `nxin ripgrep`, `nxin duf`).
function nxin() {
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
    if grep -qE "^[[:space:]]*${pkg}[[:space:]]*\$" "$file"; then
        echo "'$pkg' is already in packages.nix"
        return 0
    fi

    sed -i "0,/^[[:space:]]*\];\$/s//    ${pkg}\n  ];/" "$file"
    echo "added '$pkg' to packages.nix - re-activating Home Manager..."
    (cd "$HOME/dotfiles" && nix run home-manager/master -- switch --flake '.#zeyad')
}

# nxrm <pkg> removes the package from home.packages (nix/modules/packages.nix)
# and re-activates Home Manager. Use the Nix package name (e.g. `nxrm duf`).
function nxrm() {
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
    if ! grep -qE "^[[:space:]]*${pkg}[[:space:]]*\$" "$file"; then
        echo "'$pkg' is not in packages.nix"
        return 1
    fi

    sed -i "/^[[:space:]]*${pkg}[[:space:]]*$/d" "$file"
    echo "removed '$pkg' from packages.nix - re-activating Home Manager..."
    (cd "$HOME/dotfiles" && nix run home-manager/master -- switch --flake '.#zeyad')
}

# ADVANCED FUNCTIONS
# LazyGit - Terminal UI for Git
function lg() {
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
    lazygit "$@"
    [[ -f $LAZYGIT_NEW_DIR_FILE ]] && cd "$(cat $LAZYGIT_NEW_DIR_FILE)" && rm -f $LAZYGIT_NEW_DIR_FILE
}

# Yazi - File Manager
function yy() {
    local tmp="$(mktemp -t yazi-cwd.XXXXXX)"
    yazi "$@" --cwd-file="$tmp"
    [[ -s $tmp ]] && cd "$(cat $tmp)"
    rm -f "$tmp"
}

# Kill Process with FZF
function fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    [[ -n $pid ]] && echo $pid | xargs kill -${1:-15}
}

# Backup File with Timestamp
function bak() {
    cp "$1"{,.bak.$(date +%Y%m%d_%H%M%S)}
}

# Extract Archives
function extract() {
    [[ ! -f $1 ]] && return
    case $1 in
        *.tar.bz2) tar xjf $1 ;;
        *.tar.gz)  tar xzf $1 ;;
        *.tar.xz)  tar xJf $1 ;;
        *.bz2)     bunzip2 $1 ;;
        *.gz)      gunzip $1 ;;
        *.tar)     tar xf $1 ;;
        *.zip)     unzip $1 ;;
        *.7z)      7z x $1 ;;
        *.rar)     unrar x $1 ;;
        *)         echo "Unknown archive format" ;;
    esac
}

# Most Used Commands
function topcmd() {
    history | awk '{CMD[$2]++} END {for (a in CMD) print CMD[a], a}' |
    sort -nr | head -20
}

pnpm-auto() {
  if [[ -f package.json ]]; then
    local node_version=$(node -p "require('./package.json').engines?.node || '24.13.0'")
    pnpm env use $node_version
  fi
}

# --- Zsh Hacks Aliases ---

# Suffix Aliases (Open files based on extension)
# Usage: just type 'readme.md' and it opens in nvim
alias -s {txt,yml,yaml,toml,lua,conf,ini}=nvim
alias -s {go,js,ts,py,c,cpp,h,hpp,css,html}=nvim
alias -s json=jless
alias -s md='glow -p'

# Global Aliases (Expand anywhere in command)
# Usage: some_cmd NE (appends 2> /dev/null)
alias -g NE='2> /dev/null'
alias -g NO='&> /dev/null'
alias -g G='| grep'
alias -g C='| wl-copy'

# Named Directories (Fast navigation)
# Usage: cd ~dotfiles
hash -d dotfiles=$HOME/dotfiles
hash -d conf=$HOME/.config

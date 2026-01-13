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
alias cd='z'          # Uses zoxide for smart directory jumping

# FILE LISTING - Enhanced with eza/bat
command -v eza &>/dev/null && {
    alias ls='eza -la --icons --git'
    alias l='eza -a --icons'
    alias lt='eza -la --icons --tree --level=2 --ignore-glob="**/node_modules|**/.git"'
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
#     kubectl get secret "$@" -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
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
alias pnv="pnpm env list"
alias pn24="pnpm env use 24.12.0"
# alias pn21="pnpm env use 21.7.3"
alias docker='podman'

# SYSTEM UTILITIES
alias open='gio open'
alias c='clear'
alias gpt='tgpt'

if command -v systemctl &>/dev/null; then
    alias sctl='sudo systemctl'
    alias jctl='sudo journalctl'
fi

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
    [[ -n $pid ]] && echo $pid | xargs kill -${1:-9}
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
    local node_version=$(node -p "require('./package.json').engines?.node || '24.12.0'")
    pnpm env use $node_version
  fi
}

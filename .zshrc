# Personal Zsh Configuration
zstyle ':z4h:' start-tmux 'yes'

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
export HISTORY_IGNORE="(ls|clear|c|l|exit)"
HISTSIZE=100000
SAVEHIST=100000

zshaddhistory() {
  emulate -L zsh
  [[ $1 != ${~HISTORY_IGNORE} ]]
}

# z4h Settings
zstyle ':z4h:' auto-update 'yes'
zstyle ':z4h:' prompt-at-bottom 'no'
zstyle ':z4h:' auto-update-days '28'
zstyle ':z4h:bindkey' keyboard 'pc'
zstyle ':z4h:' term-shell-integration 'yes'
zstyle ':z4h:autosuggestions' forward-char 'accept'
zstyle ':z4h:fzf-complete' recurse-dirs 'no'
zstyle ':z4h:ssh:' enable 'no'
zstyle ':z4h:ssh:example-hostname1' enable 'yes'
zstyle ':z4h:ssh:' send-extra-files '/.nanorc' '/.env.zsh'
# zstyle ':z4h:' start-tmux no
# if ! tmux has-session 2>/dev/null; then
#   zstyle ':z4h:' start-tmux command tmux -u new -A -D -t z4h
# fi

# Initialization
z4h init || return

# Environment Variables
export BROWSER=brave
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export JS_RUNTIMES="/home/zeyad/.jsvu/bin/"
export PNPM_HOME="/home/zeyad/.local/share/pnpm"
export BUN_INSTALL="$HOME/.bun"
export ANDROID_HOME="$HOME/Android/Sdk"
typeset -U path PATH
path=(
  # $HOME/.local/share/gem/ruby/3.4.0/bin
  # $HOME/.config/composer/vendor/bin:$PATH
  $HOME/.npm-global/bin:$PATH
  $PNPM_HOME
  $JS_RUNTIMES
  $BUN_INSTALL/bin
  # $(go env GOBIN)
  $HOME/.turso
  $ANDROID_HOME/platform-tools
  $path
)
# export PHP_CS_FIXER_IGNORE_ENV=1
export QT_QPA_PLATFORM=xcb

# Tool Setup
z4h source ~/.env.zsh
eval "$(zoxide init zsh)"
eval "$(fnm env)"
autoload -Uz compinit && compinit
[ -s "/home/zeyad/.bun/_bun" ] && source "/home/zeyad/.bun/_bun"

# Key Bindings
z4h bindkey redo Alt+/
z4h bindkey undo Ctrl+/ Shift+Tab
z4h bindkey z4h-cd-back Alt+Left
z4h bindkey z4h-cd-up Alt+Up
z4h bindkey z4h-cd-down Alt+Down
z4h bindkey z4h-cd-forward Alt+Right
z4h bindkey z4h-backward-kill-word Ctrl+Backspace Ctrl+H
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace

# Shell Options
setopt glob_dots no_auto_menu

# Aliases
alias open='gio open'
## Directory navigation and listing
alias c='clear'
alias cd='z'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ls='exa -laH --group-directories-first --icons --git'
alias l='exa -aH --group-directories-first --icons'
alias lt='exa -a --tree --level=2 --icons --git'

## Editors and tools
alias v=$EDITOR
alias pn='pnpm'
alias px='pnpx'
alias t='tmux'
alias ta='t a'
alias gpt='tgpt'

## Android emulator
alias android-emulator-run='QT_QPA_PLATFORM=xcb gmtool admin start "Custom Phone"'

# Git commands
# General
alias g='git'
alias fetch='git fetch && git log HEAD..origin/$(git_branch) --oneline && git status -sb'

# Commits
alias addall='git add -A'
alias wip='git add -A && git commit -m "WIP"'
alias commit='git commit -m'
alias unstage='git reset HEAD'
alias undo='git reset --soft HEAD^'
alias amend='git add -u && git commit --amend'

# Branches
alias br='git branch -vv'
alias bd='git branch -D'
alias bm='git branch -m'
alias co='git checkout'
alias bnew='git checkout -b'

# Remote
alias push='git push'
alias pull='git pull'
alias remote='git remote -v'
alias pullr='git pull --rebase'
alias pushupstream='git push --set-upstream origin $(git_branch)'

# Stash
alias stash='git stash save'
alias unstash='git stash pop'
alias stashes='git stash list'

# Logs and Diff
alias diff='git diff --color-words'
alias log='git log --graph --pretty=format:"%h - <%an> %s (%cr)" --date=relative -10'

## Advanced
alias clean='git clean -xdf'
alias clone='gh repo clone'
alias pick='git cherry-pick'
alias pickf='git cherry-pick $(git log --oneline -50 | fzf --preview "git show --color-words {1}" | cut -d" " -f1)'

# Functions
md() {
  [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"
}
compdef _directories md

st() {
  git status -sb
  git log --oneline --decorate --color=always -3
}

lg() {
  export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
  lazygit "$@"
  [ -f $LAZYGIT_NEW_DIR_FILE ] && cd "$(cat $LAZYGIT_NEW_DIR_FILE)" && rm -f $LAZYGIT_NEW_DIR_FILE
}

yy() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  [ -n "$(cat -- "$tmp")" ] && cd "$(cat -- "$tmp")"
  rm -f -- "$tmp"
}

# Autoload
autoload -Uz zmv
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

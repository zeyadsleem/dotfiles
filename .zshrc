# Personal Zsh configuration file. It is strongly recommended to keep all
# shell customization and configuration (including exported environment
# variables such as PATH) in this file or in files sourced from it.
#
# Documentation: https://github.com/romkatv/zsh4humans/blob/v5/README.md.

# Periodic auto-update on Zsh startup: 'ask' or 'no'.
# You can manually run `z4h update` to update everything.
zstyle ':z4h:' auto-update      'no'
# Ask whether to auto-update this often; has no effect if auto-update is 'no'.
zstyle ':z4h:' auto-update-days '28'

# Keyboard type: 'mac' or 'pc'.
zstyle ':z4h:bindkey' keyboard  'pc'

# Start tmux if not already in tmux.
zstyle ':z4h:' start-tmux no

# Check if tmux is already running
if ! tmux has-session 2>/dev/null; then
  # Start tmux if not already in tmux.
  zstyle ':z4h:' start-tmux command tmux -u new -A -D -t z4h
fi

# Whether to move prompt to the bottom when zsh starts and on Ctrl+L.
zstyle ':z4h:' prompt-at-bottom 'no'

# Mark up shell's output with semantic information.
zstyle ':z4h:' term-shell-integration 'yes'

# Right-arrow key accepts one character ('partial-accept') from
# command autosuggestions or the whole thing ('accept')?
zstyle ':z4h:autosuggestions' forward-char 'accept'

# Recursively traverse directories when TAB-completing files.
zstyle ':z4h:fzf-complete' recurse-dirs 'no'

# Enable direnv to automatically source .envrc files.
zstyle ':z4h:direnv'         enable 'no'
# Show "loading" and "unloading" notifications from direnv.
zstyle ':z4h:direnv:success' notify 'yes'

# Enable ('yes') or disable ('no') automatic teleportation of z4h over
# SSH when connecting to these hosts.
zstyle ':z4h:ssh:example-hostname1'   enable 'yes'
zstyle ':z4h:ssh:*.example-hostname2' enable 'no'
# The default value if none of the overrides above match the hostname.
zstyle ':z4h:ssh:*'                   enable 'no'

# Send these files over to the remote host when connecting over SSH to the
# enabled hosts.
zstyle ':z4h:ssh:*' send-extra-files '~/.nanorc' '~/.env.zsh'

# Clone additional Git repositories from GitHub.
#
# This doesn't do anything apart from cloning the repository and keeping it
# up-to-date. Cloned files can be used after `z4h init`. This is just an
# example. If you don't plan to use Oh My Zsh, delete this line.
z4h install ohmyzsh/ohmyzsh || return

# Install or update core components (fzf, zsh-autosuggestions, etc.) and
# initialize Zsh. After this point console I/O is unavailable until Zsh
# is fully initialized. Everything that requires user interaction or can
# perform network I/O must be done above. Everything else is best done below.
z4h init || return

# Extend PATH.
path=(~/bin $path)

# Export environment variables.
export GPG_TTY=$TTY

# Source additional local files if they exist.
z4h source ~/.env.zsh

# Use additional Git repositories pulled in with `z4h install`.
#
# This is just an example that you should delete. It does nothing useful.
z4h source ohmyzsh/ohmyzsh/lib/diagnostics.zsh  # source an individual file
z4h load   ohmyzsh/ohmyzsh/plugins/emoji-clock  # load a plugin

# Define key bindings.
z4h bindkey z4h-backward-kill-word  Ctrl+Backspace     Ctrl+H
z4h bindkey z4h-backward-kill-zword Ctrl+Alt+Backspace

z4h bindkey undo Ctrl+/ Shift+Tab  # undo the last command line change
z4h bindkey redo Alt+/             # redo the last undone command line change

z4h bindkey z4h-cd-back    Alt+Left   # cd into the previous directory
z4h bindkey z4h-cd-forward Alt+Right  # cd into the next directory
z4h bindkey z4h-cd-up      Alt+Up     # cd into the parent directory
z4h bindkey z4h-cd-down    Alt+Down   # cd into a child directory

# Autoload functions.
autoload -Uz zmv

# Define functions and completions.
function md() { [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1" }
compdef _directories md

# Define named directories: ~w <=> Windows home directory on WSL.
[[ -z $z4h_win_home ]] || hash -d w=$z4h_win_home

# Set shell options: http://zsh.sourceforge.net/Doc/Release/Options.html.
setopt glob_dots     # no special treatment for file names with a leading dot
setopt no_auto_menu  # require an extra TAB press to open the completion menu

# start my custom configuration

# export editor
export EDITOR='nvim'

alias cd='z'
alias c='clear'
alias ls='exa -laH --group-directories-first --icons --git'
alias l='exa -aH --group-directories-first --icons --git'
alias lsa='exa'
alias tree='exa -T --group-directories-first --icons --git'
alias v=$EDITOR
alias pn='pnpm'
alias px='pnpx'
alias t='tmux'
alias ta='t a'
alias gpt='tgpt'
alias android-emulator-run='gmtool admin start "Custom Phone"'
alias android-emulator-stop='gmtool admin stop "Custom Phone"'

# zoxide
eval "$(zoxide init zsh)"

# cht.sh cheat sheet
cht() {
    eval cht.sh "$@" | less
}

# lazyGit 
lg()
{
    export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir

    lazygit "$@"

    if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
            cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
            rm -f $LAZYGIT_NEW_DIR_FILE > /dev/null
    fi
}

# git alias 
alias g='git'
alias clean='git clean -xdf'
alias clone='gh repo clone'
alias push='git push'
alias pushupstream='git push --set-upstream origin $(git_branch)'
alias pull='git pull'
alias commit='git commit -m'
alias amend='git commit --amend'
alias fetch='git fetch && git status'
function st {
  git status | sed -n '/Your/,/^$/p'
  git status -s && echo
  git log --pretty=format:"%h - <%an> %s (%cr)" --date=relative -3 && echo
}
alias addall='git add -A'
alias br='git branch -vv'
alias co='git checkout'
alias unstage='git reset HEAD'
alias log='git log --pretty=format:"%h - <%an> %s (%cr)" --date=relative -10'
alias stash='git stash save'
alias unstash='git stash pop'
alias stashes='git stash list'
alias pick='git cherry-pick'
alias trackedbranch='git rev-parse --abbrev-ref --symbolic-full-name @{u}'

# add yazi terminal file manger
function yy() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

# pnpm
export PNPM_HOME="/home/zeyad/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# bun completions
[ -s "/home/zeyad/.bun/_bun" ] && source "/home/zeyad/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Android Studio
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

# nodejs version manger (Volta)
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# Added by `rbenv init` on 20 ماي, 2024 EEST 08:24:30 ص
eval "$(rbenv init - zsh)"
export GEM_HOME="$HOME/.gem"

# Add laravel 
export PATH="$HOME/.config/composer/vendor/bin:$PATH"

# Add go PATH
export PATH="$PATH:$(go env GOBIN):$(go env GOPATH)/bin"

source /home/zeyad/.config/broot/launcher/bash/br

# Flutter setup
export PATH=/usr/bin/flutter/bin:$PATH
export CHROME_EXECUTABLE=/usr/bin/google-chrome-stable
export PATH=$JAVA_HOME/bin:$PATH
  export PATH="$PATH":"$HOME/.pub-cache/bin"
export PATH="$PATH":"$HOME/.pub-cache/bin"

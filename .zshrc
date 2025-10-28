# ============================================
# Powerlevel10k Instant Prompt
# ============================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ============================================
# Zinit Plugin Manager (Very Fast & Lightweight)
# ============================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit if not installed
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Load Zinit
source "${ZINIT_HOME}/zinit.zsh"

# ============================================
# Load Plugins with Zinit
# ============================================

# Syntax highlighting (must be loaded first)
zinit light zsh-users/zsh-syntax-highlighting

# Autosuggestions (like z4h)
zinit light zsh-users/zsh-autosuggestions

# Completions
zinit light zsh-users/zsh-completions

# History substring search (better than default)
zinit light zsh-users/zsh-history-substring-search

# FZF tab completion (amazing!)
zinit light Aloxaf/fzf-tab

# ============================================
# History Configuration
# ============================================
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
export HISTORY_IGNORE="(ls|clear|c|l|v|vim|exit)"

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# Custom history filter
zshaddhistory() {
  emulate -L zsh
  [[ $1 != ${~HISTORY_IGNORE} ]]
}

# ============================================
# Shell Options (similar to z4h)
# ============================================
setopt AUTO_CD              # cd by typing directory name
setopt GLOB_DOTS            # include hidden files in globbing
setopt NO_AUTO_MENU         # don't auto-complete on ambiguous input
setopt COMPLETE_IN_WORD     # complete from both ends of word
setopt ALWAYS_TO_END        # move cursor to end after completion
setopt EXTENDED_GLOB        # extended globbing
setopt NO_BEEP              # no beeping
setopt INTERACTIVE_COMMENTS # allow comments in interactive shell

# ============================================
# Environment Variables
# ============================================
export BROWSER=brave
export EDITOR=vim
export VISUAL=$EDITOR
export MANROFFOPT="-c"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

# Development paths
export JS_RUNTIMES="$HOME/.jsvu/bin"
export PNPM_HOME="$HOME/.local/share/pnpm"
export BUN_INSTALL="$HOME/.bun"
export ANDROID_HOME="$HOME/Android/Sdk"
export QT_QPA_PLATFORM=xcb
export PHP_INI_SCAN_DIR="$HOME/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"

# Build PATH
typeset -U path PATH
path=(
  $HOME/.config/herd-lite/bin
  $HOME/.npm-global/bin
  $PNPM_HOME
  $JS_RUNTIMES
  $BUN_INSTALL/bin
  $HOME/.turso
  $ANDROID_HOME/platform-tools
  $path
)

# ============================================
# FZF Configuration (Enhanced!)
# ============================================
# FZF default options
export FZF_DEFAULT_OPTS="
  --height 40%
  --layout=reverse
  --border
  --inline-info
  --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9
  --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9
  --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6
  --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4
  --preview-window=right:60%:wrap
"

# Use fd instead of find for better performance
if command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

# FZF preview with bat
export FZF_CTRL_T_OPTS="
  --preview 'bat --color=always --style=numbers --line-range=:500 {}'
  --bind 'ctrl-/:change-preview-window(down|hidden|)'
"

# FZF history search options
export FZF_CTRL_R_OPTS="
  --preview 'echo {}' 
  --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort'
  --header 'Press CTRL-Y to copy command into clipboard'
  --color header:italic
"

# FZF directory preview
export FZF_ALT_C_OPTS="
  --preview 'eza --tree --level=2 --color=always {} | head -200'
"

# Load FZF key bindings and completion
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

# Enhanced FZF history search (Ctrl+R)
fzf-history-widget-enhanced() {
  local selected
  setopt localoptions noglobsubst noposixbuiltins pipefail no_aliases 2> /dev/null
  selected="$(fc -rl 1 | awk '{ cmd=$0; sub(/^[ \t]*[0-9]+\**[ \t]+/, "", cmd); if (!seen[cmd]++) print $0 }' |
    FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} $FZF_DEFAULT_OPTS -n2..,.. --tiebreak=index --bind=ctrl-r:toggle-sort,ctrl-z:ignore $FZF_CTRL_R_OPTS --query=${(qqq)LBUFFER} +m" fzf)"
  local ret=$?
  if [ -n "$selected" ]; then
    local num=$(echo "$selected" | head -1 | awk '{print $1}' | sed 's/[^0-9]//g')
    LBUFFER="$(fc -ln $num $num | sed 's/^[ \t]*//')"
  fi
  zle reset-prompt
  return $ret
}
zle -N fzf-history-widget-enhanced
bindkey '^R' fzf-history-widget-enhanced

# ============================================
# FZF-Tab Configuration
# ============================================
# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false

# Set descriptions format to enable group support
zstyle ':completion:*:descriptions' format '[%d]'

# Set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'

# Switch group using `,` and `.`
zstyle ':fzf-tab:*' switch-group ',' '.'

# Preview for kill command
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap

# Preview for systemctl
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'

# Preview for git commands
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview \
  'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview \
  'git log --color=always $word'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview \
  'git show --color=always $word | delta'

# ============================================
# Load Powerlevel10k Theme
# ============================================
source ~/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ============================================
# NVM Configuration
# ============================================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Auto-load .nvmrc when entering directory (like z4h behavior)
autoload -U add-zsh-hook
load-nvmrc() {
  local nvmrc_path="$(nvm_find_nvmrc)"
  
  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")
    
    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$(nvm version)" ]; then
      nvm use
    fi
  elif [ -n "$(PWD=$OLDPWD nvm_find_nvmrc)" ] && [ "$(nvm version)" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc

# ============================================
# Load External Tools
# ============================================
# Zoxide (better cd) - replaces z4h cd
eval "$(zoxide init zsh)"

# Bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# Custom environment variables
[ -f ~/.env.zsh ] && source ~/.env.zsh

# ============================================
# Completion System
# ============================================
autoload -Uz compinit
compinit

# Completion styling (similar to z4h)
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu select
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' verbose yes
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'

# ============================================
# Autosuggestions Configuration
# ============================================
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'

# ============================================
# Syntax Highlighting Configuration
# ============================================
# Main highlighter types
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)

# Customize colors
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=green,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=cyan,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=blue,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=green,underline'
ZSH_HIGHLIGHT_STYLES[path]='fg=white,underline'
ZSH_HIGHLIGHT_STYLES[globbing]='fg=yellow'

# ============================================
# Key Bindings (like z4h)
# ============================================
# History search
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down
bindkey '^P' history-substring-search-up
bindkey '^N' history-substring-search-down

# Home/End
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line

# Delete
bindkey '^[[3~' delete-char

# Ctrl+Left/Right for word navigation
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Ctrl+Backspace to delete word backward (z4h style)
bindkey '^H' backward-kill-word
bindkey '^?' backward-delete-char

# Alt+Backspace to delete word backward
bindkey '^[^?' backward-kill-word

# Undo/Redo (z4h style)
bindkey '^/' undo
bindkey '^[/' redo

# Accept autosuggestion
bindkey '^[[C' forward-char  # Right arrow
bindkey '^ ' autosuggest-accept  # Ctrl+Space

# ============================================
# Aliases - General
# ============================================
alias open='gio open'
alias c='clear'
alias cd='z'
alias ...='cd ../..'
alias ....='cd ../../..'

# Modern replacements (check if commands exist)
if command -v eza &> /dev/null; then
  alias ls='eza -laH --group-directories-first --icons --git'
  alias l='eza -aH --group-directories-first --icons'
  alias lt='eza -a --tree --level=2 --icons --git'
  alias tree='eza --tree --icons'
elif command -v exa &> /dev/null; then
  alias ls='exa -laH --group-directories-first --icons --git'
  alias l='exa -aH --group-directories-first --icons'
  alias lt='exa -a --tree --level=2 --icons --git'
else
  alias ls='ls --color=auto -lah'
  alias l='ls --color=auto -a'
fi

# Bat if available
command -v bat &> /dev/null && alias cat='bat --style=plain'

# Editors and tools
alias v=$EDITOR
alias vim=$EDITOR
alias pn='pnpm'
alias px='pnpx'
alias t='tmux'
alias ta='tmux attach'
alias gpt='tgpt'

# Android
alias android-emulator-run='QT_QPA_PLATFORM=xcb gmtool admin start "Custom Phone"'

# ============================================
# Git Aliases
# ============================================
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

# Advanced
alias clean='git clean -xdf'
alias clone='gh repo clone'
alias pick='git cherry-pick'
alias pickf='git cherry-pick $(git log --oneline -50 | fzf --preview "git show --color-words {1}" | cut -d" " -f1)'

# fzf kill process
fkill() {
  local pid
  pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  if [ "x$pid" != "x" ]; then
    echo $pid | xargs kill -${1:-9}
  fi
}
# ============================================
# Functions
# ============================================

# Get current git branch
git_branch() {
  git branch 2>/dev/null | grep '^*' | colrm 1 2
}

# Create directory and cd into it
md() {
  [[ $# == 1 ]] && mkdir -p -- "$1" && cd -- "$1"
}
compdef _directories md

# Git status with recent commits
st() {
  git status -sb
  git log --oneline --decorate --color=always -3
}

# Lazygit with directory change
lg() {
  export LAZYGIT_NEW_DIR_FILE=~/.lazygit/newdir
  lazygit "$@"
  if [ -f $LAZYGIT_NEW_DIR_FILE ]; then
    cd "$(cat $LAZYGIT_NEW_DIR_FILE)"
    rm -f $LAZYGIT_NEW_DIR_FILE
  fi
}

# Yazi file manager with directory change
yy() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if [ -n "$(cat -- "$tmp")" ]; then
    cd "$(cat -- "$tmp")"
  fi
  rm -f -- "$tmp"
}

# ============================================
# Additional Tools
# ============================================
# Load zmv for mass renaming
autoload -Uz zmv

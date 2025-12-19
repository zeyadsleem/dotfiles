# Powerlevel10k Instant Prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Zinit
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [[ ! -d $ZINIT_HOME ]]; then
  mkdir -p "${ZINIT_HOME:h}"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "$ZINIT_HOME/zinit.zsh"

# FZF Configuration (TokyoNight Theme)
export FZF_DEFAULT_OPTS="
  --height 50%
  --layout=reverse
  --border=rounded
  --inline-info
  --multi
  --preview-window=right:60%:wrap:rounded:border-bold
  --bind 'ctrl-a:select-all,ctrl-d:deselect-all,ctrl-/:toggle-preview'
  --color=bg:#1a1b26,bg+:#24283b,fg:#a9b1d6,fg+:#c0caf5,hl:#7aa2f7,hl+:#7daea3
  --color=info:#88909f,prompt:#f7768e,pointer:#bb9af7,marker:#9ece6a,spinner:#f7768e,header:#7aa2f7
"

if command -v fd &> /dev/null; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi

export FZF_CTRL_T_OPTS="--preview 'bat --theme=TokyoNight --color=always --style=numbers --line-range=:500 {}' --bind 'ctrl-/:change-preview-window(down|hidden|)'"

export FZF_ALT_C_OPTS="--preview 'eza --tree --level=3 --color=always --icons --git {} | head -200'"

export FZF_CTRL_R_OPTS="
  --preview 'echo {}'
  --preview-window up:3:hidden:wrap
  --bind 'ctrl-/:toggle-preview'
  --bind 'ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort'
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

# Syntax Highlighting Styles (TokyoNight)
typeset -A FAST_HIGHLIGHT_STYLES
FAST_HIGHLIGHT_STYLES[default]='none'
FAST_HIGHLIGHT_STYLES[unknown-token]='fg=#f7768e,bold'
FAST_HIGHLIGHT_STYLES[reserved-word]='fg=#bb9af7,bold'
FAST_HIGHLIGHT_STYLES[alias]='fg=#7aa2f7'
FAST_HIGHLIGHT_STYLES[command]='fg=#7aa2f7,bold'
FAST_HIGHLIGHT_STYLES[path]='fg=#9ece6a,underline'
FAST_HIGHLIGHT_STYLES[globbing]='fg=#bb9af7'
FAST_HIGHLIGHT_STYLES[option]='fg=#e0af68'
FAST_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#9ece6a'
FAST_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#9ece6a'

# Completion System & FZF-Tab
autoload -Uz compinit
compinit
zstyle ':completion:*' rehash true
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' menu no
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'

# FZF-Tab Settings
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:complete:z:*' fzf-preview 'eza -1 --color=always $realpath'
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-flags --preview-window=down:3:wrap
zstyle ':fzf-tab:complete:systemctl-*:*' fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
zstyle ':fzf-tab:complete:git-(add|diff|restore):*' fzf-preview 'git diff $word | delta'
zstyle ':fzf-tab:complete:git-log:*' fzf-preview 'git log --color=always $word'
zstyle ':fzf-tab:complete:git-show:*' fzf-preview 'git show --color=always $word | delta'
zstyle ':fzf-tab:complete:(-command-|[^ ]*):*' fzf-preview 'echo ${(P)word}'
zstyle ':fzf-tab:complete:(\\|*/|)man:*' fzf-preview 'man $word'
zstyle ':fzf-tab:*' continuous-trigger '/'

# FZF_DEFAULT_OPTS
zstyle ':fzf-tab:*' fzf-flags --border=rounded --height=50% --preview-window=rounded:border-bold

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

# Man pages with colors using bat
export MANPAGER="sh -c 'col -bx | bat -l man -p --theme=TokyoNight'"
export MANROFFOPT="-c"

# Shell Options
setopt AUTO_CD GLOB_DOTS COMPLETE_IN_WORD ALWAYS_TO_END EXTENDED_GLOB NO_BEEP INTERACTIVE_COMMENTS COMPLETE_ALIASES

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
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=240'
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

# PATH Configuration
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/go/bin/:$PATH"
# pnpm
export PNPM_HOME="/home/zeyad/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

autoload -Uz zmv

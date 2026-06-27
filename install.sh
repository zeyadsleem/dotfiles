#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"

echo "==> bootstrapping dotfiles..."

# 1. stow symlinks for config files
if ! command -v stow &>/dev/null; then
  echo "ERROR: GNU stow is required. Install it first."
  echo "  arch:  sudo pacman -S stow"
  echo "  mac:   brew install stow"
  echo "  ubuntu:sudo apt install stow"
  exit 1
fi

echo "==> stowing configs..."
cd "$DOTFILES"
stow --restow --target "$HOME" .

# 2. symlink scripts into ~/.local/bin/
echo "==> linking scripts to ~/.local/bin/..."
mkdir -p "$HOME/.local/bin"
for script in "$DOTFILES"/.local/bin/*.sh "$DOTFILES"/.local/bin/*.py \
  "$DOTFILES"/.local/bin/editor-config "$DOTFILES"/.local/bin/swaybg \
  "$DOTFILES"/.local/bin/emoji-picker "$DOTFILES"/.local/bin/set-theme \
  "$DOTFILES"/.local/bin/set-theme-picker "$DOTFILES"/.local/bin/theme-info; do
  base=$(basename "$script")
  target="$HOME/.local/bin/$base"
  if [ ! -L "$target" ]; then
    ln -sf "$script" "$target"
    echo "  linked $base"
  fi
done

# 3. check key dependencies
echo "==> checking dependencies..."
missing=()
for cmd in nvim zsh tmux wezterm git lazygit fzf zoxide bat eza yazi niri; do
  command -v "$cmd" &>/dev/null || missing+=("$cmd")
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "WARNING: missing tools: ${missing[*]}"
  echo "  install them manually or use your package manager."
else
  echo "  all key tools found."
fi

# 4. zinit (plugin manager for zsh)
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
  echo "==> installing zinit..."
  mkdir -p "${ZINIT_HOME:h}"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# 5. tmux plugin manager
TPM_HOME="$HOME/.tmux/plugins/tpm"
if [ ! -d "$TPM_HOME" ]; then
  echo "==> installing tmux plugin manager..."
  mkdir -p "$TPM_HOME"
  git clone https://github.com/tmux-plugins/tpm "$TPM_HOME"
fi

# 6. powerlevel10k
P10K_DIR="$HOME/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "==> installing powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# 7. apply theme
if [ -x "$HOME/.local/bin/set-theme" ]; then
  echo "==> applying theme..."
  "$HOME/.local/bin/set-theme"
fi

echo ""
echo "==> done! restart your shell or run: source ~/.zshrc"
#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"

echo "==> bootstrapping dotfiles..."

# 1. Nix / Home Manager managed configs + packages
#    (note: single source of truth; dotfiles + scripts are symlinked from here)
if ! command -v nix &>/dev/null && [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
  echo "ERROR: Nix with flakes is required."
  echo "  install via the Determinate Nix installer:"
  echo "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
  exit 1
fi

echo "==> activating home-manager..."
cd "$DOTFILES"
PREV_NIX_PATH="$PATH"
export PATH="/nix/var/nix/profiles/default/bin:$PATH"
nix run home-manager/master -- switch --flake '.#zeyad'
export PATH="$PREV_NIX_PATH"

# 3. check key dependencies
echo "==> checking dependencies..."
missing=()
for cmd in nvim zsh kitty git lazygit fzf zoxide bat eza yazi niri noctalia herdr; do
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

# 5. powerlevel10k
P10K_DIR="$HOME/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "==> installing powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# 6. OpenCode integration for Herdr (runtime files live in ~/.config/opencode)
if command -v herdr &>/dev/null; then
  echo "==> installing Herdr OpenCode integration..."
  herdr integration install opencode || true
fi

echo ""
echo "==> done! restart your shell or run: source ~/.zshrc"
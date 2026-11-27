#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/dotfiles"

echo "==> bootstrapping dotfiles..."

# 1. Nix / Home Manager managed configs + packages
if ! command -v nix &>/dev/null && [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
  echo "ERROR: Nix with flakes is required."
  echo "  install via the Determinate Nix installer:"
  echo "  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install"
  exit 1
fi

# 2. Link the paths Home Manager does not own.
#    ~/.local/bin must exist before the switch: Home Manager writes the konsole
#    wrapper through it into the repo (the directory is the source of truth).
if [ -L "$HOME/.local/bin" ]; then
  ln -sfn "$DOTFILES/.local/bin" "$HOME/.local/bin"
elif [ ! -e "$HOME/.local/bin" ]; then
  ln -s "$DOTFILES/.local/bin" "$HOME/.local/bin"
else
  echo "WARNING: ~/.local/bin is a real directory; repo scripts are not linked."
fi

mkdir -p "$HOME/.local/share/applications"
for desktop in "$DOTFILES"/.local/share/applications/*.desktop; do
  [ -e "$desktop" ] || continue
  ln -sfn "$desktop" "$HOME/.local/share/applications/${desktop##*/}"
done

# 3. Activate home-manager with the CLI pinned by flake.lock (not master).
echo "==> activating home-manager..."
cd "$DOTFILES"
PREV_NIX_PATH="$PATH"
export PATH="/nix/var/nix/profiles/default/bin:$PATH"
nix run .#home-manager -- switch --flake '.#zeyad'
export PATH="$PREV_NIX_PATH"

# 4. check key dependencies
echo "==> checking dependencies..."
missing=()
for cmd in nvim zsh konsole kitty git lazygit fzf zoxide bat eza yazi niri noctalia herdr; do
  command -v "$cmd" &>/dev/null || missing+=("$cmd")
done

if [ ${#missing[@]} -gt 0 ]; then
  echo "WARNING: missing tools: ${missing[*]}"
  echo "  install them manually or use your package manager."
else
  echo "  all key tools found."
fi

# 5. zsh plugins (sourced directly at startup; zinit's layout is reused)
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/plugins"
for plugin in \
  'Aloxaf---fzf-tab https://github.com/Aloxaf/fzf-tab.git' \
  'zsh-users---zsh-autosuggestions https://github.com/zsh-users/zsh-autosuggestions.git' \
  'zdharma-continuum---fast-syntax-highlighting https://github.com/zdharma-continuum/fast-syntax-highlighting.git'
do
  dir=${plugin%% *}
  url=${plugin#* }
  if [ ! -d "$ZSH_PLUGIN_DIR/$dir" ]; then
    echo "==> installing zsh plugin: $dir..."
    mkdir -p "$ZSH_PLUGIN_DIR"
    git clone "$url" "$ZSH_PLUGIN_DIR/$dir"
  fi
done

# 6. powerlevel10k
P10K_DIR="$HOME/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  echo "==> installing powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# 7. OpenCode integration for Herdr (runtime files live in ~/.config/opencode)
if command -v herdr &>/dev/null; then
  echo "==> installing Herdr OpenCode integration..."
  herdr integration install opencode || true
fi

echo ""
echo "==> done! restart your shell or run: source ~/.zshrc"

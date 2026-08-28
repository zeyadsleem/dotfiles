# Nix + Home Manager Migration Design

**Date:** 2026-08-28
**Status:** Approved (3-layer plan agreed with user)

## Purpose

Migrate `~/dotfiles` and all user-level programs on this EndeavourOS (Arch) machine
to be managed by Nix + Home Manager, replacing the current GNU stow workflow. The
machine keeps Arch as its base (kernel, drivers, systemd, login manager stay pacman).

## Success criteria

- `home-manager switch` (via `nix run home-manager/master -- switch --flake '.#zeyad'`)
  produces the entire user environment: packages + all dotfile config links.
- GNU stow is **no longer required** for day-to-day config management. Dotfile
  changes go through the Home Manager flake.
- After a successful switch, the old stow symlinks no longer exist; new links point
  into the nix store.
- Nothing system-critical breaks: niri still runs, wallpaper/theme scripts still
  work, shell starts normally.

## Current state (inventory)

Managed by `install.sh` via stow: top-level dotfiles (`.zshrc`, `.p10k.zsh`,
`.gitconfig`, `.vimrc`, `.tmux.conf`, `.alias.zsh`, `.gtkrc-2.0`, `.face`, `.icons/`)
and `.config/` dirs (kitty, niri, waybar, swaync, kanshi, swayosd, gtklock, yazi,
tmux, lazygit, ripgrep, fastfetch, Thunar, gtk-3.0, swappy, themes/). Scripts in
`.local/bin/` get individually symlinked into `~/.local/bin`. Theme system:
`.config/themes/{orchis-dark,rose-pine-dawn}/` + `set-theme`, `set-wallpaper`,
`theme-info`, `set-theme-picker`.

Existing `nix/` flake: inputs `github:nixos/nixpkgs/nixos-unstable` +
`github:nix-community/home-manager` (follows nixpkgs), single homeConfiguration
`zeyad`. `home.nix` currently installs ~17 CLI package and enables direnv. First
successful generation is `home-manager-1-link` at
`~/.local/state/nix/profiles/`.

Nix is Determinate Nix v3.22.2 (`/nix/var/nix/profiles/default/bin`). Sandbox shell
runs as `zeyad` and can build/activate the HM config itself — user's sudo is needed
only for the resolv.conf swap when Tailscale MagicDNS is dead.

## Known hazard

Tailscale MagicDNS (`100.100.100.100`) intermittently does not answer; Nix's bundled
resolver reads `/etc/resolv.conf` directly and times out. Workaround for any
flake-fetching command:

```
sudo cp /etc/resolv.conf /etc/resolv.conf.tailscale.bak
echo 'nameserver 127.0.0.53' | sudo tee /etc/resolv.conf
<nix command>
sudo mv /etc/resolv.conf.tailscale.bak /etc/resolv.conf
```

Permanent fix option: `sudo tailscale set --accept-dns=false`.

## Architecture: 3 layers

### Layer 1 — Fully Nix-managed (packages + config)

Programs that exist in nixpkgs and are stable/safe, installed via `home.packages`:

git, neovim, ripgrep, fd, fzf, zoxide, eza, bat, tmux, jq, yq, htop, tree, unzip,
direnv, starship, lazygit, fastfetch, zsh, kitty, yazi, swaybg/backdrop,

Their config files become Home Manager modules. Priority configs:
- `programs.git` (`.gitconfig`)
- `programs.tmux` (`.tmux.conf`)
- `programs.zsh` via `programs.zsh.enable` — but the user's `.zshrc` is heavily
  custom (zinit + p10k). Decision: **keep `.zshrc` + `.p10k.zsh` as raw
  `home.file`.zshrc` copies** (not programs.zsh) to avoid breaking the running
  shell; zsh itself installed from nixpkgs.
- `programs.kitty`, `programs.yazi`, `programs.lazygit`, `programs.ripgrep`,
  `programs.fastfetch`, `programs.bat`, `programs.eza` where modules exist.
  Where no module exists, use `xdg.configFile`.

### Layer 2 — Config via HM, binary stays pacman

Window-manager / desktop critical apps that must stay rolling with Arch
(binaries untouched, configs moved into the flake so one track controls all):

- niri (`config.kdl` + `scripts/`)
- waybar (`config-niri`, `style.css`)
- swaync, swayosd, kanshi, gtklock, swappy, gtk-3.0 (`settings.ini`), Thunar
  (`accels.scm`, `uca.xml`), fastfetch fallback

Implementation: `xdg.configFile."niri/config.kdl".source = <repo path>` (etc).
These are declarative copies of the current files.

### Layer 3 — Untouched (system / infra)

- Kernel, GPU drivers, systemd, display manager, pacman base
- Theme infrastructure: scripts `set-theme`, `set-theme-picker`, `set-wallpaper`,
  `theme-info`, `theme.conf`, wallpaper images, `.face`, `.icons/` — these mutate
  state and reference `$HOME/dotfiles` paths at runtime. They depend on the repo
  layout being stable.

  BUT the scripts themselves are currently part of stow-managed dotfiles
  (`.local/bin` symlinked). To keep `install.sh`/stow fully removed, these scripts
  are re-exposed via `home.file.".local/bin/set-theme"` etc., still executed from
  the repo path. The scripts' `$HOME/dotfiles/.config/themes` assumption stays
  valid because the repo remains at `~/dotfiles` (it is the flake source anyway).

## Flake layout (proposed)

The flake must live at the **repo root** (`~/dotfiles/flake.nix`), not inside
`nix/`. Reason: a flake's source only includes the directory containing
`flake.nix` and everything under it. If the flake stays in `nix/`, any
`source = ../.config/niri/config.kdl` path is *outside* the flake source and
breaks pure evaluation (and is not reproducible/tracked). With the flake at the
root, the entire git-tracked dotfiles repo IS the flake source; every config edit
in the repo is picked up by the next switch, guarded by git.

```
dotfiles/
  flake.nix            (moved from nix/; includes the existing homeConfiguration)
  nix/
    home.nix           (top-level module, imports ./modules/*)
    modules/
      packages.nix     (layer 1: home.packages)
      git.nix          (programs.git)
      tmux.nix         (programs.tmux)
      zsh.nix          (home.file for .zshrc/.p10k.zsh; zsh package)
      kitty.nix        (programs.kitty or xdg.configFile)
      yazi.nix
      tools.nix        (lazygit, ripgrep, bat, eza, fastfetch, misc)
      dotfiles.nix     (layer 2: xdg.configFile for niri/waybar/swaync/... )
      scripts.nix      (layer 3 re-exposure: .local/bin + themes)
```

References are relative from the flake root, e.g.
`xdg.configFile."niri/config.kdl".source = ./.config/niri/config.kdl;`. No
`_module.args` indirection needed — plain relative paths.

Workflow command changes from `cd ~/dotfiles/nix` to `cd ~/dotfiles`:
`nix run home-manager/master -- switch --flake '.#zeyad'`.
The existing `nix/.envrc` (`use flake`) moves to the root so `direnv allow`
still works from `~/dotfiles`.

## Migration procedure

1. Commit current working-tree state of `~/dotfiles` (there are uncommitted
   changes: kitty.conf, Thunar/accels, nvim lockfiles, staged nix/).
2. Move `flake.nix` + `.envrc` from `nix/` to repo root; move `home.nix` logic
   into `nix/home.nix` (modules stay under `nix/modules/`). Verify the flake
   still evaluates from the new location.
3. Restructure `home.nix` into the module files above.
4. Iteratively: edit module → confirm with
   `nix eval .#homeConfigurations.zeyad.activationPackage.outPath` (fast, no switch)
   → periodically activate via `nix run home-manager/master -- switch --flake '.#zeyad'`
   run from `~/dotfiles`.
4. Verify: `home-manager-2-link` (or later) exists; `~/.config/kitty/kitty.conf`
   resolves into `/nix/store`; `niri`, `swaync`, `waybar` still run; shell opens;
   wallpaper script works.
5. Remove stow from `install.sh` (optionally delete `GNUmakefile`/install.sh stow
   step). Keep `install.sh` as the bootstrap that runs the Home Manager switch.
6. Final: `stow --delete .` from `~/dotfiles` would remove old links is NOT needed
   if HM already points links at the same destinations — Home Manager's
   `checkLinkTargets` will replace them. If conflicts are reported, delete the
   stale links then re-switch. Update `install.sh` to run the Home Manager switch
   (as bootstrap) and update README workarounds if present.

## Rollback

- Set `stateVersion` aligns to `24.05` (kept).
- Every generation is immediately reversible:
  `nix run home-manager/master -- switch --flake .#zeyad` back to a previous
  generation via `home-manager generations` + a prior `flake.lock` if needed.
- Stow stack is still present on disk (packages aren't uninstalled); if HM is
  fully broken, `~/dotfiles/install.sh` still works to rebuild symlinks.

## Out of scope (deferred)

- Migrating `lazygit`/`nvim` plugin manager internals (LazyVim stays self-managed).
- Replacing `zinit`/`p10k` with nix-managed zsh plugins (big behavior change — user
  opted for safety).
- Removing packages from pacman (mirror of packages stays; Nix packages link into
  user profile — both can coexist).
- NixOS full install (decided against).

## Testing

- `nix eval .#homeConfigurations.zeyad.activationPackage.outPath` after each module
  (compile gate).
- Actual activation and a shell/niri smoke test after full restructure.
- Validate no stray stow symlinks remain under `~/.config` that claimed the same
  target (HM activation logs link conflicts as hard errors — good).
- Confirm every config path referenced by `config.kdl`, `waybar config-niri`
  (e.g. `config.d/*.json` includes, scripts) still resolves after switch.
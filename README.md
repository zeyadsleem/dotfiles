# dotfiles

Personal dotfiles and Home Manager setup, managed declaratively with
[Nix](https://nixos.org) flakes on top of an Arch (EndeavourOS) base.

Everything lives in one repo: your shell, editor, terminal, compositor and
app configs, plus your user scripts. GNU stow is no longer used — Home Manager
owns the dots.

## Quick reference

| What you want | Do this |
|---|---|
| Add a CLI package | edit `nix/modules/packages.nix`, then re-switch |
| Remove a package | delete its line, then re-switch |
| Edit a config file | edit the live repo file (e.g. `~/.config/niri/config.kdl`), it applies on next load |
| Apply changes | `~/dotfiles/install.sh` (or the `nix run` command below) |
| Undo a broken change | `home-manager switch --rollback` |
| Change theme | run `~/.local/bin/set-theme <name>` |

## How it's organized

```
~/dotfiles
├── flake.nix            # root flake — inputs + homeConfigurations."zeyad"
├── flake.lock
├── .envrc               # `use flake` for direnv
├── nix/
│   ├── home.nix         # imports the modules below
│   └── modules/         # 8 modules, one concern each:
│       ├── packages.nix # home.packages — the CLI tool set
│       ├── git.nix      # programs.git — git global config
│       ├── tmux.nix     # links ~/.tmux.conf
│       ├── zsh.nix      # links ~/.zshrc, ~/.p10k.zsh, ~/.alias.zsh
│       ├── kitty.nix    # links kitty.conf
│       ├── yazi.nix     # links ~/.config/yazi
│       ├── dotfiles.nix # Level 2 configs (niri, waybar, swaync, …)
│       └── scripts.nix  # Level 3 user scripts → ~/.local/bin
├── .config/             # the actual configs (source of truth)
└── .local/bin/          # user scripts
```

## Activating / applying changes

From anywhere that can reach the repo:

```bash
cd ~/dotfiles
nix run home-manager/master -- switch --flake '.#zeyad'
```

or just:

```bash
~/dotfiles/install.sh
```

`install.sh` checks Nix is present, then runs the same switch. Each switch
creates a **generation** you can roll back to.

## Three-layer model

Configs are split by how risky it is to fully move them to Nix:

1. **Level 1 — fully Nix**: CLI tools in `home.packages` (`git`, `neovim`,
   `ripgrep`, `fd`, `zoxide`, `eza`, `bat`, `tmux`, `lazygit`, `delta`, `jq`,
   `yq`, `htop`, `btop`, `tree`, `unzip`, `starship`) plus the git config via
   `programs.git`.
2. **Level 2 — config only**: the *configs* for niri, waybar, swaync, kanshi,
   swayosd, gtklock, gtk-3.0 and the rest are managed by Home Manager, but the
   **binaries stay from pacman** (safer for fast-moving/GPU-tied software like
   the niri compositor).
3. **Level 3 — untouched**: the kernel/GPU drivers/systemd stay system-managed,
   and zsh/fzf/p10k/zinit stay on pacman because `~/.zshrc` hardcodes
   `/usr/share/...` paths that a Nix-provided binary would break. Your
   `~/.local/bin` scripts and theme switcher are symlinked but otherwise
   untouched.

## How the dots get to ~

Home Manager writes a small directory of links under `/nix/store/*-home-manager-files`.
Those links point **out-of-store** at the live repo (`$HOME/dotfiles`) via
`mkOutOfStoreSymlink`. That's deliberate: several configs — `set-theme` targets
like `~/.config/themes/current`, `waybar/colors.css`, `yazi/theme.toml` — are
**rewritten at runtime**, so they must not be frozen read-only into the store.

The flake computes that path rather than using `./.`:

```nix
_module.args.dotfilesDir = config.home.homeDirectory + "/dotfiles";
```

Using `./.` would copy the repo into the store during evaluation and all those
symlinks would end up pointing at a read-only snapshot, breaking theme switching.

> If you tried to run this on a machine without Nix as the provider for a
> that-tool, remember: most dev tools (Node, Python, Rust, pnpm, nvm, mise…)
> live happily outside Nix. Home Manager owns the *tooling and config*, not
> every runtime.

## Notes / pitfalls already hit

- **No `executable = true` on out-of-store script links.** Home Manager builds
  `executable = true` files with `cp`, which dereferences the symlink to the
  live-repo path *outside* the Nix sandbox and fails the build. The repo scripts
  are already `+x`, so plain symlinks preserve executability. (`scripts.nix`)
- **One path, one manager.** Don't declare `.config/lazygit` as a whole directory
  in one module *and* `.config/lazygit/config.yml` per-file in another — Home
  Manager errors with `Error installing file ... outside $HOME`. Link each path
  exactly once.
- **Keep fzf/zsh on pacman** — `~/.zshrc` sources `/usr/share/fzf/key-bindings.zsh`
  and `/usr/share/zsh/site-functions`, which only exist from the Arch packages.

## Next steps / ideas

- Add more tools to `home.packages` as you use them.
- Optionally fold more read-only configs into `text = ''...''` inside modules for
  a stricter "declarative" setup — only sensible where nothing rewrites them at
  runtime.

## Reference

- Design doc: `docs/superpowers/specs/2026-08-28-nix-home-manager-migration-design.md`

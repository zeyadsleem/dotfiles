# dotfiles

Personal dotfiles and Home Manager setup, managed declaratively with
[Nix](https://nixos.org) flakes on top of an Arch (EndeavourOS) base.

Everything lives in one repo: shell, editor, terminal, compositor, desktop
shell and app configs, plus user scripts. GNU stow is no longer used —
Home Manager owns the dots.

The desktop is **Niri + Noctalia**: Niri manages windows, Noctalia owns the
bar, launcher, notifications, OSD, clipboard, wallpaper, lock screen and
session actions. Terminal agents run under **Herdr**, whose Noctalia plugin
shows agent state in the bar.

## Quick reference

| What you want | Do this |
|---|---|
| Add a CLI package | edit `nix/modules/packages.nix`, then re-switch |
| Remove a package | delete its line, then re-switch |
| Edit a config file | edit the live repo file (e.g. `~/.config/niri/config.kdl`), it applies on next load |
| Apply changes | `~/dotfiles/install.sh` (or the `nix run` command below) |
| Undo a broken change | `home-manager switch --rollback` |
| Open apps | `Mod+Space` (Noctalia launcher) or the bar icon |
| Control center | `Mod+S` |
| Noctalia settings | `Mod+Shift+Comma` |
| Change wallpaper | `wp`, or Noctalia control center → Wallpaper |
| Lock the screen | `Super+Alt+L` |
| Power menu | `Mod+Shift+E` |
| Notifications | `Mod+Shift+N` (control center, notifications tab) |
| Clipboard history | `Mod+C` |
| Window switcher | hold `Alt+Tab` (reverse: `Alt+Shift+Tab`) |
| Terminal sessions | `herdr`, or `hs` / `hc` for the shell/code sessions |

Noctalia reads `~/.config/noctalia/config.toml`. Changes made in its GUI or
through `noctalia msg` are written to `~/.local/state/noctalia/settings.toml`
and override the repo config — check that file when a change does not stick.

## The dot CLI

`dot` is a read-only inventory and health check for this machine. It answers
*what is installed* and *who owns it* across pacman, the Nix profile, tool
shims, scripts and config files.

| Command | What it tells you |
|---|---|
| `dot list` | what is installed (apps, CLI tools, scripts, managed configs) |
| `dot list --all` | every item, ungrouped |
| `dot list --ownership` | who owns each config file |
| `dot list --json` | machine-readable |
| `dot status` | broken links, stale copies, missing binaries, drift |
| `dot status --json` | machine-readable findings |

`dot status` exits `1` when it finds problems.

| Command | What it does |
|---|---|
| `dot health` | fast health check for scripts and niri spawn targets |
| `dot pkg list` | packages declared in `nix/modules/packages.nix` |
| `dot pkg add <name>` | add a package and apply it |
| `dot pkg rm <name>` | remove a package and apply it |
| `dot pkg sync` | apply the list as it stands |
| `dot browse` | fzf launcher over apps, CLI tools, scripts and configs |
| `dot keys` | Niri cheat sheet, parsed from the live config (Arabic by default) |
| `dot show <id>` | details of one item |

`dot pkg` is the only mutating command: it edits `nix/modules/packages.nix`,
shows the diff, asks before writing, and restores the file if the switch fails.
It never uses `sudo`.

## How it's organized

```
~/dotfiles
├── flake.nix            # root flake — inputs + homeConfigurations."zeyad"
├── flake.lock
├── .envrc               # `use flake` for direnv
├── nix/
│   ├── home.nix         # imports the modules below
│   └── modules/         # one concern each:
│       ├── packages.nix # home.packages — the CLI tool set
│       ├── git.nix      # programs.git
│       ├── zsh.nix      # links ~/.zshrc, ~/.p10k.zsh, ~/.alias.zsh
│       ├── kitty.nix    # links kitty.conf
│       ├── yazi.nix     # links ~/.config/yazi
│       └── dotfiles.nix # Level 2 configs (niri, noctalia, kanshi, apps)
├── .config/             # the actual configs (source of truth)
└── .local/bin/          # user scripts
```

## Activating / applying changes

```bash
cd ~/dotfiles
nix run home-manager/master -- switch --flake '.#zeyad'
```

or:

```bash
~/dotfiles/install.sh
```

Each switch creates a **generation** you can roll back to.

## Three-layer model

1. **Level 1 — fully Nix**: CLI tools in `home.packages` (`git`, `neovim`,
   `ripgrep`, `fd`, `zoxide`, `eza`, `bat`, `lazygit`, `delta`, `jq`, `yq`,
   `htop`, `btop`, `tree`, `unzip`) plus the git config via `programs.git`.
2. **Level 2 — config only**: the *configs* for Niri, Noctalia, kanshi,
   gtk-3.0 and the apps are managed by Home Manager, but the **binaries stay
   from pacman** (safer for fast-moving/GPU-tied software like the compositor).
3. **Level 3 — untouched**: kernel/GPU drivers/systemd stay system-managed;
   zsh/fzf/p10k/zinit stay on pacman because `~/.zshrc` sources
   `/usr/share/...` paths that a Nix-provided binary would break.

## How the dots get to ~

Home Manager writes a small directory of links under
`/nix/store/*-home-manager-files`. Those links point **out-of-store** at the
live repo (`$HOME/dotfiles`) via `mkOutOfStoreSymlink`. That is deliberate:
Noctalia writes generated theme files at runtime (GTK CSS, Kitty palette,
palettes under `~/.config/noctalia/`), so the targets must not be frozen
read-only into the store.

The flake computes that path rather than using `./.`:

```nix
_module_args.dotfilesDir = config.home.homeDirectory + "/dotfiles";
```

Using `./.` would copy the repo into the store during evaluation and all those
symlinks would point at a read-only snapshot.

## Herdr

Herdr is the terminal/agent runtime that replaced tmux and workmux:

```bash
herdr                     # TUI
herdr session attach      # attach to a session
hs                        # attach to the "shell" session
hc                        # attach to the "code" session
herdr machine list        # configured machines
```

The Noctalia plugin `hy4ri/herdr` (v1.2.1, plugin API 43) adds a bar widget
and panel. On Niri it focuses an existing terminal window instead of opening a
duplicate; this needs `NIRI_SOCKET` in Noctalia's environment (it inherits it
from the Niri session) and the `niri` + `ps` tools.

`install.sh` runs `herdr integration install opencode` once. Those files land
in `~/.config/opencode` (a separate repo) and are runtime state, not dotfiles.

## Shell AI helpers

- `gpt <question>` — `opencode run` on the free `opencode/big-pickle` model.
  `-c` continues the last session, `-m provider/model` overrides the model.
- `img <prompt>` — free image generation through the pollinations.ai endpoint
  `tgpt` uses, no API key; saves to `~/Pictures/ai` and opens the result.

## Notes / pitfalls already hit

- **No `executable = true` on out-of-store script links.** Home Manager builds
  `executable = true` files with `cp`, which dereferences the symlink to the
  live-repo path *outside* the Nix sandbox and fails the build. The repo scripts
  are already `+x`, so plain symlinks preserve executability.
- **One path, one manager.** Don't declare `.config/lazygit` as a whole
  directory in one module *and* `.config/lazygit/config.yml` per-file in
  another — Home Manager errors with `Error installing file ... outside $HOME`.
  Link each path exactly once.
- **Keep fzf/zsh on pacman** — `~/.zshrc` sources
  `/usr/share/fzf/key-bindings.zsh` and `/usr/share/zsh/site-functions`, which
  only exist from the Arch packages.
- **Noctalia needs `libjxl 0.12`.** Installing `noctalia` without a full
  `pacman -Syu` leaves the old `libjxl` and the binary fails with
  `libjxl_threads.so.0.12: cannot open shared object file`. On this machine
  `libjxl` is pinned in `/etc/pacman.conf` (`IgnorePkg = libjxl libvdpau`),
  so `pacman -Syu` skips it. Until that line is removed, a wrapper at
  `~/.local/bin/noctalia` runs `/usr/bin/noctalia` against a user-local copy
  of the library in `~/.local/lib/noctalia-libjxl`. Fix it permanently with:

  ```bash
  sudo sed -i 's/^IgnorePkg.*/#&/' /etc/pacman.conf
  sudo pacman -Syu
  ```

  Once `/usr/lib/libjxl_threads.so.0.12` exists the wrapper is a passthrough.
- **Noctalia template writes.** The Kitty template skips an existing
  `kitty.conf`; the repo config includes `themes/*.conf` explicitly so the
  generated palette is still loaded.

## Reference

- Noctalia: <https://noctalia.dev> — Niri integration:
  <https://docs.noctalia.dev/noctalia/compositor-settings/niri/>
- Herdr: <https://herdr.dev> — Noctalia plugin:
  <https://noctalia.dev/plugins/community/herdr>
- Migration design: `docs/superpowers/specs/2026-11-05-noctalia-migration-design.md`
- Earlier design: `docs/superpowers/specs/2026-08-28-nix-home-manager-migration-design.md`

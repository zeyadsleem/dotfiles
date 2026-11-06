# Noctalia Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the hand-built Waybar/SwayNC/SwayOSD/gtklock/theme/wallpaper desktop stack with Noctalia 5.4.1, and replace tmux/workmux with Herdr.

**Architecture:** Noctalia owns the shell layer (bar, launcher, notifications, OSD, lock screen, clipboard, wallpaper, session, polkit agent). Niri keeps window management and gains Noctalia startup/binds/rules. Herdr owns terminal sessions and agent state; its Noctalia plugin surfaces agent status in the bar. Nix/Home Manager links the new configs out of the store; legacy configs and packages are removed.

**Tech Stack:** Niri 26.04, Noctalia 5.4.1 (pacman), Herdr 0.9.5 (`herdr-bin`), Home Manager/Nix, Kitty, zsh.

**Spec:** `docs/superpowers/specs/2026-11-05-noctalia-migration-design.md`

## Global Constraints

- Noctalia `5.4.1-1` or newer; `hy4ri/herdr` plugin v1.2.1 (plugin API 43) so Niri focus works.
- `libjxl 0.12.0-1` must be installed; Noctalia currently fails with `libjxl_threads.so.0.12: cannot open shared object file`.
- Keep Niri. Do not add Umbriel or a greeter.
- Keep `fuzzel` (headset-popup-daemon and emoji-picker depend on it).
- Keep `kanshi`, `hyprpicker`, `swappy`, `wl-clipboard`, `libnotify`, `wl-clip-persist` if present.
- All repo config links use `mkOutOfStoreSymlink`; Noctalia templates write through them.
- Wallpapers live in `~/Pictures/Wallpapers`; seed with the current Nord image.
- Native Niri Print binds and `screenshot-path` stay; Noctalia screenshot policy is not required.
- No timed idle lock. Lock stays manual/noctalia IPC.
- No secrets in the repo.

## Review Focus

- Noctalia starts without a compositor crash and owns the bar, notifications, OSD, clipboard, and lock screen.
- Niri binds no longer call deleted scripts (`waybar`, `swaync`, `swayosd`, `gtklock`, `app-menu`, `cliphist`, `switch-layout`).
- `Mod+Space` opens the Noctalia launcher; `Mod+S` opens the control center; `Mod+Shift+Comma` opens settings.
- Herdr bar widget shows agent state and focuses an existing Niri window (needs `NIRI_SOCKET` and plugin 1.2.1).
- Kitty gets Noctalia colors without losing the existing font/opacity config.
- `home-manager switch` succeeds and `dot status` reports no broken symlinks.

---

### Task 1: Preflight and Noctalia runtime

**Files:**
- Verify: `/usr/bin/noctalia`, `/usr/bin/herdr`

- [ ] Upgrade the partial system so `libjxl 0.12.0-1` is installed: `sudo pacman -Syu`.
- [ ] Verify `noctalia --version` prints `5.4.1` and `herdr --version` prints `0.9.5`.
- [ ] Ensure the Noctalia config dir exists: `mkdir -p ~/.config/noctalia`.
- [ ] Confirm the Herdr plugin can resolve API 43 in Noctalia Settings → Plugins.

### Task 2: Noctalia configuration

**Files:**
- Create: `.config/noctalia/config.toml`
- Create: `.config/noctalia/palettes/nord.json` only if a custom palette is needed (start without it).
- Modify: `nix/modules/dotfiles.nix` (link `.config/noctalia/config.toml` and `.config/noctalia/palettes` if created).
- Create: `~/Pictures/Wallpapers/nord.jpg` (copy `.config/themes/nord/wallpaper.jpg`).

**Interfaces:**
- Produces: `noctalia msg panel-toggle launcher|control-center|wallpaper|clipboard|session`, `noctalia msg session lock`, `noctalia msg window-switcher`.

- [ ] Write the config with: font `Maple Mono NF`; one top bar (`thickness 34`, `radius 12`, `margin_ends 180`, `margin_edge 10`, `padding 14`, `reserve_space true`, `compositor_blur true`); start `["launcher","wallpaper","workspaces"]`; center `["clock"]`; end `["privacy","tray","notifications","clipboard","keyboard_layout","separator","network","separator","volume","separator","brightness","separator","cpu","separator","ram","separator","temp","separator","battery","separator","session","separator","hy4ri/herdr:bar"]`.
- [ ] `[shell]` `polkit_agent = true`, `telemetry_enabled = false`, `clipboard_enabled = true`, `niri_overview_type_to_launch_enabled = false`, `font_family = "Maple Mono NF"`.
- [ ] `[wallpaper]` `directory = "/home/zeyad/Pictures/Wallpapers"`, `default.path = "/home/zeyad/Pictures/Wallpapers/nord.jpg"`, `transition = ["fade"]`, `transition_duration = 800`, automation disabled.
- [ ] `[theme]` `mode = "dark"`, `source = "wallpaper"`, `wallpaper_scheme = "m3-content"`; templates `builtin_ids = ["btop","gtk3","gtk4","kitty","qt"]`, `enable_community_templates = false`.
- [ ] `[notification] enable_daemon = true`; `[osd]` all kinds true except `bluetooth` (adapter disabled) and `keyboard_layout` (single layout), `hide_delay_ms = 1400`; `[lockscreen] enabled = true`, `blurred_desktop = false`, `transition = ["fade"]`; idle lock/screen-off disabled.
- [ ] `[plugins] enabled = ["hy4ri/herdr"]`, `auto_update = "none"`; sources official and community enabled.
- [ ] Add the config and palette dir links in `nix/modules/dotfiles.nix`.

### Task 3: Niri integration

**Files:**
- Modify: `.config/niri/config.kdl`

- [ ] `spawn-at-startup "noctalia"`; remove `waybar`, `swaync`, `swayosd-server`, `set-wallpaper --supervise`, `polkit-gnome`, `app-menu`, and both `wl-paste | cliphist` startup lines.
- [ ] Keep `kanshi`, `nm-applet`, `gnome-keyring`, `protonvpn-app`, `headset-popup-daemon`.
- [ ] Remove `swayidle + lock-if-not-running.sh`; Noctalia lock is manual; keep XF86Sleep suspend.
- [ ] Binds: `Mod+Space` → `noctalia msg panel-toggle launcher`; `Mod+S` → `panel-toggle control-center`; `Mod+Shift+Comma` → `settings-toggle`; `Alt+Tab` → `window-switcher hold`; `Alt+Shift+Tab` → `window-switcher hold reverse`; `Super+Alt+L` → `noctalia msg session lock`; `Mod+Shift+E` → `noctalia msg panel-toggle session`; `Mod+C` → `panel-toggle clipboard`; `Mod+Shift+N` → `notification-clear-active`; `Mod+B`/`Mod+Shift+B` Brave unchanged; `Mod+Shift+P` Thunar unchanged.
- [ ] Volume/brightness/media keys → `noctalia msg volume-up/down/mute` and `brightness-up/down`; keep `playerctl` media binds.
- [ ] Remove `Mod+Shift+D` app-menu, `Mod+Shift+Space` dot menu, `Mod+Ctrl+Grave`/`Mod+Shift+Grave` toggle-waybar, `Mod+Space switch-layout`, `Mod+Shift+N swaync` old action.
- [ ] Add window rule: `match app-id="dev.noctalia.Noctalia"` floating, `default-size 1080 920`; keep rounded `20` + clip rule for shell surfaces.
- [ ] Add layer rules for Noctalia blur namespaces from the Niri integration page; if using flat wallpaper, skip backdrop rules.
- [ ] Add `debug { honor-xdg-activation-with-invalid-serial }` if it is not already present.
- [ ] Remove `polkit-gnome` window rules; add Noctalia polkit dialog rule if needed.

### Task 4: Kitty and terminal theme

**Files:**
- Modify: `.config/kitty/kitty.conf`
- Keep: `.config/kitty/tode/keybinds.kitty.conf`
- Remove: `include ../themes/current/kitty/theme.conf` line.

- [ ] Add `include themes/noctalia.conf` at the end (Noctalia kitty template writes `~/.config/kitty/themes/noctalia.conf`).
- [ ] Ensure `themes/` is writable (repo dir if linked) or let Noctalia write through the out-of-store link.
- [ ] Keep font/opacity/window settings unchanged.

### Task 5: Remove the legacy desktop stack

**Files to delete:**
- `.config/waybar/`, `.config/swaync/`, `.config/swayosd/`, `.config/gtklock/`
- `.config/themes/` (after copying the Nord wallpaper out; keep no theme pipeline)
- `.local/bin/app-menu`, `set-theme`, `set-theme-picker`, `theme-info`, `set-wallpaper`, `wallpaper-picker`, `toggle-waybar.sh`, `lock-if-not-running.sh`, `power-menu-niri.sh`, `switch-layout.sh`
- `nix/modules/tmux.nix`, `.tmux.conf`, `.config/tmux/`, `.config/opencode/plugins/workmux-status.ts`, `.config/workmux/`
- Remove their links from `nix/modules/dotfiles.nix`; remove `./modules/tmux.nix` from `nix/home.nix`.
- Remove packages from `nix/modules/packages.nix`: `tmux`, the `workmux` derivation.
- Remove packages from the system/host list (pacman, not Nix): `waybar`, `swaync`, `swayosd`, `gtklock`, `nwg-drawer`, `cliphist`, `polkit-gnome`, `swayidle`. Keep `fuzzel`, `kanshi`, `hyprpicker`, `swappy`, `wl-clipboard`, `libnotify`.

- [ ] Copy `~/Pictures` wallpaper(s) needed and delete `.config/themes` only after confirming Noctalia wallpaper path works.
- [ ] Remove `.config/nvim/lua/current_theme.lua` references to the old theme pipeline (keep the file if Neovim uses it; repoint to Noctalia community neovim template only if enabled).
- [ ] Remove `.zshrc` line sourcing `~/.config/themes/current/zsh/env.zsh`; remove `t`/`ta`/`wp` aliases, add `wp='noctalia msg panel-toggle wallpaper'`, `h='herdr'`.

### Task 6: Herdr and OpenCode integration

**Files:**
- Modify: `.alias.zsh`
- Modify: `install.sh`
- Modify: `README.md`

- [ ] Keep `herdr-bin` installed; add `herdr` to the install script's checks.
- [ ] Run `herdr integration install opencode` once; its files under `~/.config/opencode` are runtime state (separate repo), do not link them here.
- [ ] Replace tmux aliases with `alias h='herdr'`, `alias hs='herdr session attach shell'`, `alias hc='herdr session attach code'`.
- [ ] Remove TPM installation from `install.sh`; keep zinit/p10k.

### Task 7: Trim `dot` and tests

**Files:**
- Modify: `.local/bin/dot`
- Modify: `tests/test_dot.py`

- [ ] Remove the `menu` subcommand and its renderer/runner (the Noctalia launcher replaces it); keep `list`, `status`, `pkg`, `browse`, `show`, `keys`, `health` (health remains read-only and harmless).
- [ ] Delete `BarTests` and `MenuTests` (they assert Waybar/app-menu files that no longer exist).
- [ ] Run `python3 -m pytest tests/test_dot.py -q` and fix only migration-caused failures.

### Task 8: Documentation and design update

**Files:**
- Modify: `docs/superpowers/specs/2026-11-05-noctalia-migration-design.md`
- Modify: `README.md`

- [ ] Update the design: Noctalia 5.4.1 (not 5.3.0), Herdr 1.2.1 Niri focus works, keep fuzzel, screenshots stay native Niri, no media OSD, no `dot menu`.
- [ ] README: replace Waybar/SwayNC/SwayOSD/gtklock/tmux/workmux sections with Noctalia + Herdr usage (`Mod+Space`, `Mod+S`, `Mod+Shift+Comma`, `noctalia msg ...`, `herdr session attach`).

### Task 9: Apply and verify

- [ ] `nix run home-manager/master -- switch --flake .#zeyad` (or `./install.sh`) succeeds.
- [ ] `dot status` has no broken symlinks.
- [ ] Start a fresh Niri session; confirm Noctalia bar, launcher, control center, notifications, OSD, clipboard, wallpaper, lock screen.
- [ ] Confirm `NIRI_SOCKET` is visible to Noctalia (`/proc/$(pgrep -x noctalia)/environ`).
- [ ] Enable `hy4ri/herdr` in Noctalia; confirm the bar widget and panel; run `herdr` and an OpenCode session; click a session and confirm the existing Niri window focuses.
- [ ] Confirm `Mod+Space`, `Mod+S`, `Mod+Shift+Comma`, `Alt+Tab`, `Super+Alt+L`, volume/brightness keys.
- [ ] Run `python3 -m pytest tests/test_dot.py -q`.
- [ ] Commit with Conventional Commits only when the user asks.

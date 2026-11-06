# Noctalia migration design

**Date:** 2026-11-05
**Status:** awaiting approval
**Decision owner:** Zeyad

## Intent

The desktop shell has grown into a second project: a hand-written Waybar,
four theme-aware helper directories, a wallpaper supervisor, a menu, a
lock screen, an OSD daemon, and a tmux/agent plugin stack. The request is
to delete that plumbing and let Noctalia own the shell, while Herdr
replaces tmux and its agent-status integrations. The reference pattern is
[h4ni0/dotfiles](https://github.com/h4ni0/dotfiles): a small declarative
Noctalia config, a generated theme consumed by apps, and Herdr sessions
instead of tmux.

Niri stays. It is the compositor; Noctalia is the shell that runs on it.
Umbriel (the Noctalia compositor) and Greeter are **not** part of this
migration.

## Goals

1. Remove every custom shell component: Waybar, SwayNC, SwayOSD, gtklock,
   the theme switcher, the wallpaper supervisor/picker, the app menu, the
   dot menu, and their scripts/tests/docs.
2. One Noctalia TOML owns bar, launcher, clipboard, notifications, OSD,
   lock screen, session menu, screenshots, and theming.
3. Herdr replaces tmux for terminals and agent sessions; the Noctalia
   Herdr plugin shows agent state in the bar.
4. The repo stays the single source of truth: configs are linked from
   `~/dotfiles` by Home Manager, exactly like today.
5. The result is smaller: fewer files, fewer packages, no bespoke
   theme/wallpaper daemons.

## Non-goals

- No change to the compositor (Niri), terminal (kitty), browser (Brave),
  file manager (Thunar), shell (zsh/p10k), or editor (Neovim).
- No Noctalia Greeter, no Umbriel, no greetd/PAM work.
- No new custom status scripts, no plugin authoring.
- No automatic `sudo`/`pacman` execution by the agent. System package
  commands are documented for the user to run.
- No redesign of the Niri layout bindings (windows, columns, workspaces).

## Anti-goals

- Re-implementing a removed feature with a new custom script. If Noctalia
  does not do it, it is dropped, not rebuilt.
- Keeping “just in case” copies of Waybar/SwayNC/SwayOSD/gtklock/themes.
- Two bars, two launchers, two clipboards, or two notification daemons
  running at once.

## Constraints

- Arch/EndeavourOS base; Niri 26.04, kitty 0.49.2, Home Manager flake.
- Binaries that come from the distro (Niri, kitty, Waybar today) are
  installed with pacman. HM owns configs and CLI tools. Noctalia and Herdr
  follow that rule: pacman/AUR binaries, repo-linked config.
- Noctalia 5.3.0 is in Arch `[extra]`; `herdr-bin` 0.9.5 is in the AUR.
- `mkOutOfStoreSymlink` links are writable, which Noctalia's theme
  templates require, but Noctalia must not rewrite files HM owns. Its
  generated files go to app config dirs (e.g. `kitty/themes/noctalia.conf`),
  never back into the linked source.
- Niri must start Noctalia before/alongside the bar; there is no systemd
  user service dependency.
- `NIRI_SOCKET` must be present in Noctalia's environment for the Herdr
  plugin's focus integration.

## Target stack

| Concern | Today | After |
|---|---|---|
| Bar | Waybar + `config-niri` + CSS + 2 scripts | Noctalia bar (`[bar.main]`) |
| Notifications | SwayNC + `swaync-client` | Noctalia notification daemon |
| OSD | SwayOSD server + client | Noctalia OSD |
| Lock screen | gtklock + `lock-if-not-running.sh` | Noctalia lockscreen |
| Launcher | fuzzel + nwg-drawer + `app-menu` | Noctalia launcher |
| Clipboard | cliphist + `wl-paste` watchers + fuzzel | Noctalia clipboard panel |
| Session/power menu | `power-menu-niri.sh` + fuzzel | Noctalia session panel |
| Theme switching | `set-theme` + `.config/themes` | Noctalia palette + templates |
| Wallpaper | `set-wallpaper --supervise` + picker | Noctalia wallpaper |
| Keyboard layout switch | `switch-layout.sh` (ydotool + SwayOSD) | Niri `grp:alt_shift_toggle` only |
| Screenshots | Niri native + `swappy` | Noctalia screenshot IPC (+ existing `swappy` config stays) |
| Terminal multiplexer | tmux + TPM + cht.sh | Herdr |
| Agent status | `workmux-status.ts` + workmux | Herdr + `hy4ri/herdr` plugin |
| Alt-tab | none | Noctalia window switcher |
| Focused window title | Waybar `niri/window` | dropped (Noctalia has no window-title widget) |
| Idle/suspend lock | swayidle → gtklock | Noctalia `lock_before_suspend` |
| Polkit agent | `polkit-gnome` | Noctalia `polkit_agent = true` |
| Output profiles | kanshi | kanshi (unchanged) |

## Architecture

### Packaging

- `noctalia` from Arch `[extra]` (`sudo pacman -S noctalia`), currently
  **5.4.1-1**. The user installs it during this migration. Reason: it is
  a session binary like Niri; Arch tracks it; no flake input or HM module
  is needed just to run it. Noctalia 5.4.1 provides plugin API 43, so the
  current Herdr plugin (v1.2.1) resolves and Niri focus works.
- Installing Noctalia without a full upgrade left `libjxl 0.11.1-5`
  installed while `noctalia 5.4.1` needs `libjxl 0.12.0-1`. Run
  `sudo pacman -Syu` before starting the session.
- `herdr-bin` from the AUR (`yay -S herdr-bin`). The Noctalia plugin
  expects the `herdr` CLI on `PATH`. The desktop app is optional and not
  installed by default.
- Remove `tmux` and the custom `workmux` derivation from
  `nix/modules/packages.nix`.
- Keep `kanshi`, `wl-clipboard`, `hyprpicker`, `libnotify`, `swappy`.
- System packages to uninstall after the switch is verified:
  `waybar swaync swayosd gtklock nwg-drawer cliphist polkit-gnome swayidle`.
  `tmux` is removed from the Nix profile; the pacman tmux (if present) is
  also removed. `kanshi` and `fuzzel` stay: `headset-popup-daemon` and
  `emoji-picker` call `fuzzel` directly.

### Repository layout

Add:

```
.config/noctalia/config.toml      # the single shell config
.config/noctalia/palettes/        # only if a custom palette is kept; empty otherwise
```

Optionally add a minimal `~/.config/herdr/` config later; the migration
starts with Herdr defaults so there is nothing to maintain.

Home Manager links `.config/noctalia/config.toml` per file (not the whole
directory) so Noctalia can keep palettes/cache in that directory without
orphaning anything.

### Noctalia config outline

The exact keys are validated against the installed 5.3 schema; the
structure follows the reference config.

- `[bar]` one bar named `main`:
  - top, thickness 40, radius 8, margin_edge 5, margin_ends 10,
    padding 15, scale 1.1, `background_opacity = 0.9`,
    `reserve_space = true`, `shadow = false`, `widget_spacing = 10`.
  - `start = ["workspaces"]`
  - `center = ["clock_start", "clock", "clock_end"]` (text brackets, same
    look as the reference)
  - `end = ["privacy", "tray", "notifications", "keyboard_layout",
    "separator", "net-down", "separator", "volume", "separator",
    "brightness", "separator", "cpu", "separator", "ram", "separator",
    "temp", "separator", "battery", "separator", "session", "separator",
    "herdr"]`
  - `font_family = "Maple Mono NF"` (matches kitty; verified with fc-list)
- `[shell]`: `polkit_agent = true`, `clipboard_enabled = true`,
  `clipboard_keep_from_closed_apps = true`, `setup_wizard_enabled = false`,
  `telemetry_enabled = false`, font `Maple Mono NF`.
- `[shell.screenshot]`: directory `~/Pictures/Screenshots`,
  `save_to_file = true`, `copy_to_clipboard = true`,
  `freeze_screen = true`, `show_cursor = false`, format `png`.
- `[notification] enable_daemon = true`.
- `[osd] enabled = true` with volume/brightness/keyboard-layout/privacy/
  media kinds. There is no media widget in the target bar, so the media
  OSD is the only feedback for the media keys (matching today).
- `[lockscreen] enabled = true`, `fingerprint = false`,
  `lock_before_suspend` left at its default (true).
- `[idle]`: no timed lock, matching today's swayidle (which only locked
  before sleep). Screen-off timeout disabled. Suspend locks via Noctalia.
- `[control_center]` shortcuts: bluetooth, caffeine, nightlight,
  notification, power profile, system.
- `[dock] enabled = false`, `[desktop_widgets] enabled = false`,
  `[system.monitor] enabled = true`.
- `[theme]`: `mode = "dark"`, `source = "wallpaper"`,
  `wallpaper_scheme = "m3-rainbow"`, built-in templates:
  `btop, gtk3, gtk4, kitty, qt`. Community templates start disabled; each
  one writes into an app config and can be enabled after checking the
  output path. `enable_builtin_templates = true`.
- `[wallpaper]`: directory `~/Pictures/Wallpapers` (a dedicated folder,
  not all of `~/Pictures`, which contains screenshots and AI images),
  seeded with the current Nord wallpaper copied to
  `~/Pictures/Wallpapers/nord.jpg` before the old theme directory is
  deleted. No `automation` (no random rotation) until the user asks for
  it. Wallpaper stays flat: no backdrop layer, no stationary wallpaper
  layer, overview keeps the normal Niri background.
- `[plugins]`: `enabled = ["hy4ri/herdr"]`, `auto_update = false`,
  official + community sources enabled. The plugin is installed by
  Noctalia on first run; config is only the enable list. **On Noctalia
  5.3.0 the store resolves to plugin v1.1.0 (plugin API 26)** because
  v1.2.1 requires API 43 (Noctalia 5.4+). v1.1.0 predates the
  `reuse existing terminal windows on Niri` change, so the bar count and
  panel work but clicking a session opens a new terminal instead of
  focusing the existing Niri window. Full focus is deferred until Arch
  ships 5.4.x or the user switches to `noctalia-git`; the design does not
  pin an unsupported plugin version.
- `[widget.herdr]`: `type = "hy4ri/herdr"` (exact widget type taken from
  the installed plugin manifest), `display_mode = "icon_and_count"`,
  `hide_count_when_zero = false`, `hide_agentless_panes = true`,
  `show_other_machines = false`, colors on theme tokens.
- Widget tuning mirrors the reference: clock format `{:%H:%M %p}` with a
  date tooltip; workspace labels as IDs; CPU as a graph; RAM/temp/net as
  text; volume with label; privacy hides inactive icons; tray hidden
  entries left empty.

Noctalia may write `~/.local/state/noctalia/settings.toml` for GUI
changes. That file is runtime state, not repo-managed; if a change is
worth keeping it is copied back into `config.toml`.

### Niri changes

Startup (`spawn-at-startup`):

- Add `noctalia`.
- Remove: `polkit-gnome-authentication-agent-1`, `set-wallpaper
  --supervise`, `swaync`, `swayosd-server`, both `wl-paste`/cliphist
  watchers, `nm-applet`, `app-menu`, `waybar`.
- Keep: `kanshi`, `gnome-keyring-daemon`, `protonvpn-app`,
  `headset-popup-daemon`.
- Remove `swayidle` (Noctalia owns idle/suspend locking).

Binds:

| Bind | Action |
|---|---|
| `Mod+D` / `Mod+Space` | `noctalia msg panel-toggle launcher` |
| `Mod+S` | `noctalia msg panel-toggle control-center` |
| `Mod+Shift+Comma` | `noctalia msg settings-toggle` |
| `Alt+Tab` | `noctalia msg window-switcher hold` |
| `Alt+Shift+Tab` | `noctalia msg window-switcher hold reverse` |
| `Mod+C` | `noctalia msg panel-toggle clipboard` |
| `Mod+Shift+N` | `noctalia msg panel-toggle control-center notifications` |
| `Mod+Shift+E` | `noctalia msg panel-toggle session` |
| `Super+Alt+L` | `noctalia msg session lock` |
| `Mod+Shift+A` | `noctalia msg panel-toggle hy4ri/herdr:panel` |
| `Mod+Ctrl+Grave`, `Mod+Shift+Grave` | `noctalia msg bar-toggle` |
| `Print` / `Ctrl+Print` / `Alt+Print` | Noctalia `screenshot-region` / `screenshot-fullscreen` / `screenshot-window` |
| Volume keys | `noctalia msg volume-up/down/mute` |
| Brightness keys | `noctalia msg brightness-up/down` |
| Media keys | `noctalia msg media previous/next/play-pause` |
| `XF86Sleep` | `noctalia msg session lock-and-suspend` |
| `Mod+Shift+D` | removed (launcher is `Mod+D`) |
| `Mod+Shift+Period` | keep `hyprpicker --autocopy` |
| everything else | unchanged |

Window/layer rules:

- Noctalia settings window: `app-id="dev.noctalia.Noctalia"`,
  `open-floating true`, fixed ~1080×920, rounded 20, clip.
- Layer rules for `^noctalia-(bar-[^"]+|notification|dock|panel|attached-panel|osd)$`
  and the window switcher, enabling blur so panels match the existing
  blurred Niri look.
- Wallpaper: keep it flat (no backdrop layer). The current desktop is a
  normal wallpaper behind windows; no new backdrop behavior.
- Add `debug { honor-xdg-activation-with-invalid-serial }` from the Niri
  integration guide.
- Keep the existing app window rules (kitty, Thunar, Brave, ProtonVPN,
  dialogs). Remove rules that only existed for shell helpers if any
  remain (none beyond polkit agents, which stay for other agents).

### Herdr replacement

- Remove `.tmux.conf`, `.config/tmux/`, the tmux package, TPM bootstrap in
  `install.sh`, `tmux-cht.sh`, `tmux-session-wizard.sh`, the workmux
  derivation, `.config/workmux/`, and
  `.config/opencode/plugins/workmux-status.ts`.
- Remove the tmux aliases and wallpaper alias from `.alias.zsh`; add
  `h='herdr'`, `hs='herdr session attach shell'`, and
  `hc='herdr session attach code'`. `wp` becomes
  `noctalia msg panel-toggle wallpaper`.
- Herdr's core starts on demand; no custom startup script unless testing
  shows the plugin cannot see a core. If a persistent core is needed, add
  one `spawn-at-startup` line in Niri, not a daemon script.
- OpenCode stays the agent. Herdr reads its state from the screen without
  extra files; run `herdr integration install opencode` to also get
  native session resume. That writes
  `~/.config/opencode/plugins/herdr-agent-state.js`,
  `~/.config/opencode/herdr-tui-session.js`, and
  `~/.config/opencode/herdr-opencode/tui.js` (plus registrations). Those
  files belong to the separate `~/.config/opencode` git repo as runtime
  state, not to this dotfiles repo.

### Theme pipeline

- The eight hand-made themes and `set-theme`/`theme-info`/pickers are
  deleted. Noctalia derives a palette from the wallpaper and applies it
  through templates.
- Kitty: replace `include ../themes/current/kitty/theme.conf` with
  `globinclude themes/*.conf`; Noctalia writes `themes/noctalia.conf`.
  The glob keeps Kitty usable before the template has run. Keep the rest
  of `kitty.conf` (fonts, opacity, keybinds) untouched.
- GTK 3/4, Qt, btop get generated theme files. GTK `settings.ini` stays
  HM-linked; if the GTK template tries to own it, the template is dropped
  and GTK keeps the linked file (builder check during implementation).
- Neovim is **not** re-themed by this migration. Its local config and any
  colorscheme stay as they are; the community `neovim` template is
  enabled only if it writes outside the existing config.
- The old zsh theme hook (`.zshrc` line 36) is removed; p10k keeps its
  current static colors.

### What stays

- Niri config (layout, binds unrelated to the shell, window rules).
- kitty, zsh/p10k, Neovim, Yazi, lazygit, fastfetch, Thunar, Brave,
  mimeapps, `.gtkrc-2.0`, `.face`, `.icons`, `.vimrc`.
- `kanshi` output profiles.
- `dot` **core**: `list`, `status`, `pkg` (inventory/ownership is still
  useful and is not shell plumbing). `health`, `browse`, `keys`, `menu`,
  `show` are deleted with the shell they served.
- `arabic-time.py`, `emoji-picker`, `headset-popup-daemon`,
  `force-suspend.sh`, `disable-pbtn-wake.sh`, `gpt`/`img` helpers.
- `fuzzel` (used by `headset-popup-daemon` and `emoji-picker`),
  `hyprpicker`, `swappy`, `wl-clipboard`, `libnotify`.

## File-by-file change list

Delete:

- `.config/waybar/`
- `.config/swaync/`
- `.config/swayosd/`
- `.config/gtklock/`
- `.config/themes/`
- `.config/tmux/`
- `.tmux.conf`
- `.config/workmux/`
- `.config/opencode/plugins/workmux-status.ts`
- `.local/bin/app-menu`
- `.local/bin/set-theme`
- `.local/bin/set-theme-picker`
- `.local/bin/theme-info`
- `.local/bin/set-wallpaper`
- `.local/bin/wallpaper-picker`
- `.local/bin/toggle-waybar.sh`
- `.local/bin/lock-if-not-running.sh`
- `.local/bin/power-menu-niri.sh`
- `.local/bin/switch-layout.sh`
- `.local/bin/tmux-cht.sh`
- `.local/bin/tmux-session-wizard.sh`
- `.local/bin/hijri-date.py`
- `nix/modules/tmux.nix`

Add:

- `.config/noctalia/config.toml`
- `.config/noctalia/palettes/` only if a custom palette survives review

Edit:

- `.config/niri/config.kdl`: startup, binds, Noctalia window/layer rules,
  debug block.
- `.config/kitty/kitty.conf`: theme include.
- `.zshrc`: drop the theme-env source.
- `.alias.zsh`: tmux/wallpaper aliases.
- `nix/home.nix`: drop the `tmux` import.
- `nix/modules/dotfiles.nix`: remove links for deleted files; add the
  Noctalia config link; remove the workmux links.
- `nix/modules/packages.nix`: remove `tmux` and the workmux derivation.
- `install.sh`: drop tmux/TPM; update the dependency check (remove tmux,
  add noctalia/herdr).
- `README.md`: replace the theme/wallpaper/menu/tmux sections with
  Noctalia/Herdr; update the `dot` command table.
- `tests/test_dot.py`: keep core `dot` tests, delete Waybar/theme/menu
  tests, add a link/config sanity test for the new files.

## Verification

1. `nix flake check` / `nix run home-manager/master -- switch --flake
   '.#zeyad'` succeeds; no dangling links (`home-manager` reports none).
2. `noctalia msg status` responds under Niri; `noctalia` starts from a
   fresh Niri session with no Waybar/SwayNC/SwayOSD/gtklock process.
3. Bar shows workspaces, clock, network, volume, CPU/RAM/temp, tray,
   keyboard layout, privacy, session, Herdr; blur applies to bar and
   panels.
4. Launcher (`Mod+Space`; `Mod+D` is the fuzzel fallback), clipboard
   (`Mod+C`), control center (`Mod+S`),
   session (`Mod+Shift+E`), settings (`Mod+Shift+Comma`), window switcher
   (`Alt+Tab`), bar toggle, lock, and suspend-lock all work.
5. Screenshots from all three Print binds save to
   `~/Pictures/Screenshots` and copy to the clipboard.
6. Volume/brightness/media keys show Noctalia OSD and change state.
7. Kitty follows the Noctalia palette; GTK apps follow it; btop follows
   it.
8. `herdr session attach` opens a session; two sessions can run
   concurrently; the Herdr bar widget shows agent counts and the panel
   opens with `Mod+Shift+A` or a click on the widget. With Noctalia
   5.4.1 and plugin v1.2.1, clicking a session focuses the existing Niri
   window.
9. `dot list`, `dot status`, `dot pkg list` still work; removed commands
   are gone; `dot status` reports no broken links.
10. Old services are gone: no `waybar`, `swaync`, `swayosd-server`,
    `gtklock`, `cliphist`, `polkit-gnome`, `swayidle`, `app-menu` in
    `pgrep`/autostart.
11. Reboot into Niri once to prove the session is not dependent on a
    leftover process.

Rollback: `home-manager switch --rollback` restores the links, and the
migration is one git commit (or a short series) that can be reverted. The
old packages are only uninstalled after step 11 passes.

## Risks

- **Noctalia 5.3 + Herdr plugin**: the store installs plugin v1.1.0 on
  5.3 (API 26), which predates Niri focus/reuse. Bar count and panel
  work; clicking a session opens a new terminal. Full focus needs
  Noctalia 5.4+, so this is the one known regression until Arch ships
  5.4.x (or the AUR `noctalia-git` is used).
- **Noctalia 5.3 ↔ Niri 26.04**: layer-shell blur and `honor-xdg-activation`
  are the two integration points most likely to need a version tweak.
  Verify before deleting the old bar; keep Waybar installed until the new
  session passes.
- **Herdr plugin schema**: widget type/ID comes from the plugin manifest,
  not from this document. Read the manifest after install; do not guess.
- **HM links vs generated files**: Noctalia must never write through an
  HM symlink. Generated files go to sibling paths (kitty `themes/`,
  `gtk-3.0/gtk.css`). If a template wants to replace a linked file,
  disable that template.
- **Two daemons**: SwayNC/Noctalia notifications or SwayOSD/Noctalia OSD
  both running would double-pop. Startup removal must land in the same
  switch as the Noctalia config.
- **Clipboard history loss**: cliphist history is not migrated. If the
  user needs it, copy `~/.cache/cliphist/db` before uninstalling; Noctalia
  starts its own history.
- **Herdr session state**: tmux sessions are not migrated; they are
  ephemeral by design. Open new Herdr sessions.

## Builder's calls (made here, changeable)

1. **Noctalia via pacman 5.3.0.** The user installs it; matches the
   existing distro-binary rule and avoids an HM systemd service. Config
   is still repo-managed. The Herdr focus limitation is accepted above.
2. **Herdr TUI only** (`herdr-bin`), no desktop app. The panel and bar
   widget only need the CLI. The app can be added later.
3. **One bar**, not the reference's two. The second “pilled” bar is a
   style experiment, not a feature this setup used.
4. **Keep `dot` core, delete its shell-facing commands.** Inventory is
   independent of the shell and still answers “what owns this file”.
5. **Wallpaper-derived palette** (`source = "wallpaper"`) instead of
   porting one of the eight hand-made palettes. This is the “stop
   maintaining themes” outcome; a custom palette can be added later.
6. **No timed idle lock** to preserve current behavior; suspend still
   locks. This is a security-relevant default and is called out for the
   user to override.
7. **No random wallpaper rotation** until asked.
8. **Community app templates disabled at first**, built-in
   kitty/gtk/qt/btop enabled. Avoids writing into HM-linked configs.
9. **Keep kanshi**, because Noctalia does not manage output profiles.
10. **Keep `hyprpicker`**, because Noctalia has no documented color picker.
11. **Keep the current Nord wallpaper** by copying it to
    `~/Pictures/Wallpapers/nord.jpg` before deleting `.config/themes`.
12. **Keep `fuzzel`** because `headset-popup-daemon` and `emoji-picker`
    call it directly. Noctalia still owns the launcher; fuzzel is only a
    tiny dmenu utility for those two scripts.

## Left to the builder

- Exact Noctalia key names/values for 5.3 (the outline above is the
  contract; the plan validates against the installed schema).
- Exact Herdr widget type and plugin settings keys from the installed
  manifest.
- Whether the GTK template can coexist with the HM-linked
  `settings.ini`; if not, drop the template.
- Whether Herdr core needs an explicit startup line for the plugin to see
  sessions.
- Test-file surgery details for `tests/test_dot.py`.

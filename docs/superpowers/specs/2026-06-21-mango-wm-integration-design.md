# Mango WM Integration into Dotfiles

## Overview

Add [Mango WM](https://github.com/mangowm/mango) (v0.14.4, dwm-inspired wlroots compositor)
to the existing stow-based dotfiles at `~/dotfiles`, alongside the current Sway config,
and port the user's Sway workflow to Mango-native syntax.

## Motivation

The user wants to switch from Sway to Mango while keeping their existing scripts (screenshots,
clipboard, power menu, etc.) and tools (Waybar, swaync, swayosd, wezterm, fuzzel, etc.).
All configuration must live in `~/dotfiles` and be managed via GNU stow.

## File Structure

```
.config/mango/
├── config.conf          # Main config — sources sub-files, visuals, appearance, autostart
├── env.conf             # Environment variables (GTK/QT IME, XDG portals)
├── input.conf           # Keyboard layout, repeat rate, touchpad, mouse
├── monitor.conf         # Monitor rules (output config)
├── bind.conf            # All keybindings (ported from sway/config.d/default)
├── rule.conf            # Window rules (ported from sway/config.d/application_defaults)
├── tag.conf             # Tag rules (layout per tag)
└── autostart.sh         # exec-once script (polkit, waybar, swaync, nm-applet, etc.)
```

### Location Convention

All files live under `dotfiles/.config/mango/`. GNU stow links them to `~/.config/mango/`.

Sway config remains untouched under `dotfiles/.config/sway/`. Both WM entries are available
from the Display Manager (DM) via their respective `.desktop` files.

## Waybar Adjustments

Waybar uses several Sway-specific modules that need changes:

| Module | Change Needed |
|--------|--------------|
| `sway/workspaces` | Replace with `wlr/workspaces` (tags-based) |
| `sway/mode` | Remove (Mango uses keymodes via different mechanism) |
| `sway/language` | Replace with custom script using `mmsg get keyboardlayout` |
| `sway/window` | Keep — works via wlr-foreign-toplevel-management |

The rest (network, clock, pulseaudio, battery, tray, backlight, notification, power) remain
unchanged.

## Keybinding Migration Pattern

Sway syntax                          | Mango syntax
-------------------------------------|--------------------------
`bindsym $mod+Return exec wezterm`   | `bind=SUPER,Return,spawn,wezterm`
`bindsym $mod+q kill`                | `bind=SUPER,q,killclient`
`bindsym $mod+Shift+r reload`        | `bind=SUPER,r,reload_config`
`bindsym $mod+d exec fuzzel`         | `bind=SUPER,d,spawn,fuzzel`
`bindsym XF86AudioRaiseVolume exec swayosd-client --output-volume raise` | `bind=NONE,XF86AudioRaiseVolume,spawn,swayosd-client --output-volume raise`
`exec_always <cmd>`                  | `exec-once=<cmd>` (autostart)

### Key Mappings

- `$mod` (Mod4) = `SUPER`
- `$left`/`$down`/`$up`/`$right` (h/j/k/l) handled per-binding
- `Shift` = `SHIFT`, `Ctrl` = `CTRL`, `Alt` = `ALT`
- `--locked` flag → `bindl` prefix
- `--to-code` → Mango matches by keysym by default (only use keycode if layout issues)

## Window Rule Migration

Sway                                         | Mango
---------------------------------------------|--------------------------
`for_window [app_id="pavucontrol"] floating enable` | `windowrule=isfloating:1,appid:pavucontrol`
`for_window [floating] move position center`  | (center is default for Mango floating)
`for_window [app_id="waybar_btop"] floating enable, resize set 1200 900, opacity 0.92` | `windowrule=isfloating:1,width:1200,height:900,focused_opacity:0.92,appid:waybar_btop`

## Visual & Effects Migration

SwayFX config                            | Mango equivalent
-----------------------------------------|--------------------------
`shadows enable`                         | `shadows=1`
`blur enable, blur_passes 2`            | `blur=1, blur_params_num_passes=2`
`corner_radius 10`                       | `border_radius=10`
`default_dim_inactive 0.1`               | (unfocused_opacity handles this)
`smart_gaps on, smart_borders on`        | `smartgaps=1, no_border_when_single=1`

Mango includes built-in animations (slide/zoom/fade for open/close/tag transitions)
that SwayFX did not have.

## Autostart Migration

Sway (`exec`/`exec_always`) → Mango `exec-once=` in config + `autostart.sh` script:

- Polkit agent
- GNOME keyring
- Kanshi
- swayidle
- swaync
- swayosd-server
- cliphist (text + image)
- nm-applet
- nwg-drawer
- protonvpn-app
- swaybg (wallpaper)

## Shared Scripts

The following scripts under `dotfiles/.config/sway/scripts/` are compositor-agnostic
and will be used as-is by Mango (referenced by absolute path):

- `power_menu.sh`
- `screenshot_area.sh`
- `screenshot_full.sh`
- `screenshot_window_quick.sh`
- `screenshot_window.sh`

Scripts that are SwayFX-specific (`swayfader.py`) are omitted.

## Implementation Steps

1. Create `dotfiles/.config/mango/` directory structure
2. Write `env.conf` — environment variables (IME, Qt, portals)
3. Write `input.conf` — keyboard layout (us,ara), repeat rate, touchpad config
4. Write `monitor.conf` — output rules (ported from sway/config.d/output)
5. Write `rule.conf` — window rules (floating for dialogs, apps, browsers)
6. Write `tag.conf` — tag rules (layouts per tag)
7. Write `bind.conf` — all keybindings ported from sway
8. Write `config.conf` — main config (visuals, animations, colors, appearance, sourcing)
9. Write `autostart.sh` — startup applications
10. Update Waybar config — replace Sway-specific modules
11. Update `install.sh` — add mango to dependency check
12. Verify with `mango -p` config validation
13. Run stow and test

## Non-Goals

- Removing or altering the existing Sway config
- Writing documentation beyond this spec
- Ensuring Mango works on non-Arch systems
- Porting `swayfx_effects` settings that have no Mango equivalent

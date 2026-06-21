# Mango WM Setup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add Mango WM config to `~/dotfiles` alongside Sway, porting the user's Sway workflow (keybindings, window rules, autostart, visuals) to Mango-native format.

**Architecture:** Modular config structure under `.config/mango/` with separate files for env, input, monitor, bindings, rules, tags, and autostart. All sourced from `config.conf`. Sway config remains untouched.

**Tech Stack:** Mango WM v0.14.4, GNU stow, bash (autostart.sh), Waybar (with wlr modules)

---

### Task 1: Create directory and env.conf

**Files:**
- Create: `.config/mango/env.conf`

- [ ] Create the mango config directory

```bash
mkdir -p /home/zeyad/dotfiles/.config/mango
```

- [ ] Write `env.conf`

```conf
# Environment Variables
env=GTK_IM_MODULE,fcitx
env=QT_IM_MODULE,fcitx
env=QT_IM_MODULES,wayland;fcitx
env=SDL_IM_MODULE,fcitx
env=XMODIFIERS,@im=fcitx
```

- [ ] Commit

```bash
git add .config/mango/env.conf
git commit -m "feat(mango): add env.conf with IME environment variables"
```

---

### Task 2: Write input.conf

**Files:**
- Create: `.config/mango/input.conf`

- [ ] Write `input.conf`

```conf
# Keyboard Layout and Repeat Rate
xkb_rules_layout=us,ara
xkb_rules_options=grp:alt_shift_toggle
repeat_rate=35
repeat_delay=200
numlockon=1

# Touchpad
tap_to_click=1
tap_and_drag=1
drag_lock=1
trackpad_natural_scrolling=0
disable_while_typing=1
left_handed=0

# Mouse
mouse_natural_scrolling=0

# Focus
sloppyfocus=1
warpcursor=1
focus_on_activate=1
```

- [ ] Commit

```bash
git add .config/mango/input.conf
git commit -m "feat(mango): add input.conf with keyboard, touchpad, mouse config"
```

---

### Task 3: Write monitor.conf

**Files:**
- Create: `.config/mango/monitor.conf`

- [ ] Write `monitor.conf`

```conf
# Monitor Rules — uncomment and adjust for your displays
# Use `wlr-randr` to find your monitor specs
# monitorrule=name:^eDP-1$,width:1920,height:1080,refresh:60,x:0,y:0
# monitorrule=name:^HDMI-A-1$,width:1280,height:1024,refresh:60,x:1920,y:0
```

- [ ] Commit

```bash
git add .config/mango/monitor.conf
git commit -m "feat(mango): add monitor.conf with commented example rules"
```

---

### Task 4: Write rule.conf

**Files:**
- Create: `.config/mango/rule.conf`

- [ ] Write `rule.conf`

```conf
# =============================================================================
# Window Rules (ported from sway/config.d/application_defaults)
# =============================================================================

# Standard floating rules for dialogs and popups
windowrule=isfloating:1,title:dialog
windowrule=isfloating:1,title:utility
windowrule=isfloating:1,title:toolbar
windowrule=isfloating:1,title:splash
windowrule=isfloating:1,title:menu
windowrule=isfloating:1,title:pop-up
windowrule=isfloating:1,title:popup_menu
windowrule=isfloating:1,title:tooltip
windowrule=isfloating:1,title:notification
windowrule=isfloating:1,title:about
windowrule=isfloating:1,title:preferences
windowrule=isfloating:1,title:bubble

# Authentication & Portals
windowrule=isfloating:1,appid:polkit-gnome-authentication-agent-1
windowrule=isfloating:1,appid:lxqt-policykit-agent
windowrule=isfloating:1,appid:org.kde.polkit-kde-authentication-agent-1
windowrule=isfloating:1,appid:gcr-prompter
windowrule=isfloating:1,appid:xdg-desktop-portal-gtk

# Specific Applications
windowrule=isfloating:1,appid:pavucontrol
windowrule=isfloating:1,appid:nm-connection-editor
windowrule=isfloating:1,appid:blueman-manager
windowrule=isfloating:1,appid:qalculate-gtk

# Thunar Dialogs
windowrule=isfloating:1,appid:thunar,title:File Operation Progress
windowrule=isfloating:1,appid:thunar,title:Confirm to replace files

# Archivers & Image Viewers
windowrule=isfloating:1,appid:org.gnome.FileRoller
windowrule=isfloating:1,appid:org.gnome.Loupe

# Custom Terminal Windows (WezTerm)
windowrule=isfloating:1,width:1200,height:900,focused_opacity:0.92,appid:waybar_btop
windowrule=isfloating:1,width:900,height:700,focused_opacity:0.92,appid:waybar_nmtui
windowrule=isfloating:1,width:1100,height:800,focused_opacity:0.92,appid:wezterm_floating

# Browser Dialog Rules
windowrule=isfloating:1,width:800,height:600,appid:brave,title:(?i)(save file|open file)
windowrule=isfloating:1,appid:brave,title:(?i)(extension|picture-in-picture)
windowrule=isfloating:1,width:800,height:600,appid:chromium,title:(?i)(save file|open file)
windowrule=isfloating:1,appid:chromium,title:(?i)(extension|picture-in-picture)

# Picture-in-Picture
windowrule=isfloating:1,title:Picture-in-Picture
windowrule=isfloating:1,title:Picture in picture

# Terminal swallowing for WezTerm
windowrule=isterm:1,appid:wezterm
windowrule=isterm:1,appid:org.wezfurlong.wezterm
```

- [ ] Commit

```bash
git add .config/mango/rule.conf
git commit -m "feat(mango): add rule.conf with window rules ported from sway"
```

---

### Task 5: Write tag.conf

**Files:**
- Create: `.config/mango/tag.conf`

- [ ] Write `tag.conf`

```conf
# Tag Rules — layout per tag (tile layout default for all)
tagrule=id:1,layout_name:tile
tagrule=id:2,layout_name:tile
tagrule=id:3,layout_name:tile
tagrule=id:4,layout_name:tile
tagrule=id:5,layout_name:tile
tagrule=id:6,layout_name:tile
tagrule=id:7,layout_name:tile
tagrule=id:8,layout_name:tile
tagrule=id:9,layout_name:tile
```

- [ ] Commit

```bash
git add .config/mango/tag.conf
git commit -m "feat(mango): add tag.conf with tile layout for all tags"
```

---

### Task 6: Write bind.conf

**Files:**
- Create: `.config/mango/bind.conf`

- [ ] Write `bind.conf`

```conf
# =============================================================================
# Mango Key Bindings (ported from sway/config.d/default + sway/config.d/input)
# =============================================================================

# Reload config
bind=SUPER,r,reload_config

# Terminal
bind=SUPER,Return,spawn,wezterm

# Launcher
bind=SUPER,d,spawn,fuzzel
bind=SUPER+SHIFT,d,spawn,nwg-drawer -term wezterm

# Power menu
bind=SUPER+SHIFT,e,spawn,~/.config/sway/scripts/power_menu.sh

# Kill focused window
bind=SUPER,q,killclient

# Lock screen
bind=SUPER,F1,spawn,gtklock

# Activities
bind=SUPER,p,spawn,cerebro

# =============================================================================
# Focus & Movement
# =============================================================================

# Arrow keys
bind=SUPER,Left,focusdir,left
bind=SUPER,Down,focusdir,down
bind=SUPER,Up,focusdir,up
bind=SUPER,Right,focusdir,right

# Vim keys
bind=SUPER,h,focusdir,left
bind=SUPER,j,focusdir,down
bind=SUPER,k,focusdir,up
bind=SUPER,l,focusdir,right

# Move windows with arrows
bind=SUPER+SHIFT,Left,exchange_client,left
bind=SUPER+SHIFT,Down,exchange_client,down
bind=SUPER+SHIFT,Up,exchange_client,up
bind=SUPER+SHIFT,Right,exchange_client,right

# Move windows with Vim keys
bind=SUPER+SHIFT,h,exchange_client,left
bind=SUPER+SHIFT,j,exchange_client,down
bind=SUPER+SHIFT,k,exchange_client,up
bind=SUPER+SHIFT,l,exchange_client,right

# =============================================================================
# Tags (ported from Sway workspace bindings)
# =============================================================================

# Switch to tag (like Sway $mod+number)
bind=SUPER,1,view,1
bind=SUPER,2,view,2
bind=SUPER,3,view,3
bind=SUPER,4,view,4
bind=SUPER,5,view,5
bind=SUPER,6,view,6
bind=SUPER,7,view,7
bind=SUPER,8,view,8
bind=SUPER,9,view,9

# Move window to tag (like Sway $mod+Shift+number)
bind=SUPER+SHIFT,1,tag,1
bind=SUPER+SHIFT,2,tag,2
bind=SUPER+SHIFT,3,tag,3
bind=SUPER+SHIFT,4,tag,4
bind=SUPER+SHIFT,5,tag,5
bind=SUPER+SHIFT,6,tag,6
bind=SUPER+SHIFT,7,tag,7
bind=SUPER+SHIFT,8,tag,8
bind=SUPER+SHIFT,9,tag,9

# Navigate tags left/right
bind=SUPER,comma,viewtoleft,0
bind=SUPER,period,viewtoright,0

# Move window to tag left/right
bind=CTRL+SUPER,comma,tagtoleft,0
bind=CTRL+SUPER,period,tagtoright,0

# Previous tag
bind=SUPER,Tab,focuslast,

# =============================================================================
# Layout
# =============================================================================

# Cycle layouts
bind=SUPER,n,switch_layout

# Fullscreen
bind=SUPER,f,togglefullscreen,

# Floating toggle
bind=SUPER+SHIFT,space,togglefloating,

# Maximize
bind=SUPER+SHIFT,m,togglemaximizescreen,

# Focus parent (up in hierarchy)
bind=SUPER,a,focusdir,up

# =============================================================================
# Scratchpad
# =============================================================================

# Move to scratchpad
bind=SUPER+SHIFT,minus,minimized

# Show scratchpad
bind=SUPER,minus,toggle_scratchpad

# =============================================================================
# Resizing
# =============================================================================

# Arrow keys
bind=SUPER+CTRL,Right,resizewin,+10,0
bind=SUPER+CTRL,Up,resizewin,0,+10
bind=SUPER+CTRL,Down,resizewin,0,-10
bind=SUPER+CTRL,Left,resizewin,-10,0

# Vim keys
bind=SUPER+CTRL,l,resizewin,+10,0
bind=SUPER+CTRL,k,resizewin,0,+10
bind=SUPER+CTRL,j,resizewin,0,-10
bind=SUPER+CTRL,h,resizewin,-10,0

# =============================================================================
# Media Keys (bindl = locked mode, works even when screen is locked)
# =============================================================================

# Volume
bindl=NONE,XF86AudioRaiseVolume,spawn,swayosd-client --output-volume raise
bindl=NONE,XF86AudioLowerVolume,spawn,swayosd-client --output-volume lower
bindl=NONE,XF86AudioMute,spawn,swayosd-client --output-volume mute-toggle

# Player
bindl=NONE,XF86AudioPlay,spawn,playerctl play-pause
bindl=NONE,XF86AudioNext,spawn,playerctl next
bindl=NONE,XF86AudioPrev,spawn,playerctl previous

# Backlight
bindl=NONE,XF86MonBrightnessUp,spawn,swayosd-client --brightness raise
bindl=NONE,XF86MonBrightnessDown,spawn,swayosd-client --brightness lower

# Sleep
bind=NONE,XF86Sleep,spawn,systemctl suspend

# =============================================================================
# App Shortcuts
# =============================================================================

# File explorer
bind=SUPER,e,spawn,thunar

# Browser
bind=SUPER,o,spawn,brave

# Clipboard manager (select from history)
bind=SUPER,c,spawn_shell,cliphist list | fuzzel -d -w 50 -l 15 -p "Select from clipboard:  " | cliphist decode | wl-copy

# Clipboard delete entry
bind=SUPER,x,spawn_shell,cliphist list | fuzzel -d -w 50 -l 15 -t cc9393ff -S cc9393ff -p "Select an entry to delete it from cliphist:  "| cliphist delete

# Color picker
bind=SUPER,i,spawn,hyprpicker --autocopy

# Window switcher
bind=SUPER+SHIFT,w,spawn,~/.config/sway/scripts/window_switcher.sh

# =============================================================================
# Screenshots
# =============================================================================

# Quick selection (like Cmd+Shift+4)
bind=NONE,Print,spawn,~/.config/sway/scripts/screenshot_area.sh

# Full display (like Cmd+Shift+3)
bind=SHIFT,Print,spawn,~/.config/sway/scripts/screenshot_full.sh

# Quick window screenshot
bind=CTRL,Print,spawn,~/.config/sway/scripts/screenshot_window_quick.sh

# Annotation mode
bind=ALT,Print,spawn_shell,grim -g "$(slurp)" - | swappy -f -

# =============================================================================
# Utility
# =============================================================================

# Emoji picker
bind=SUPER+SHIFT,period,spawn,~/.local/bin/emoji-picker

# Notifications center
bind=SUPER+SHIFT,n,spawn,swaync-client -t -sw

# Theme Selector
bind=SUPER+SHIFT,t,spawn,~/.local/bin/set-theme-picker

# Keyboard layout switch
bind=SUPER,space,switch_keyboard_layout

# Toggle Waybar visibility
bind=SUPER,grave,spawn,pkill -SIGUSR1 waybar

# Gaps
bind=ALT+SHIFT,x,incgaps,1
bind=ALT+SHIFT,z,incgaps,-1
bind=ALT+SHIFT,r,togglegaps

# =============================================================================
# Mouse Bindings
# =============================================================================

mousebind=SUPER,btn_left,moveresize,curmove
mousebind=SUPER,btn_right,moveresize,curresize

# =============================================================================
# Axis Bindings (scroll on tag bar area)
# =============================================================================

axisbind=SUPER,UP,viewtoleft_have_client
axisbind=SUPER,DOWN,viewtoright_have_client
```

- [ ] Commit

```bash
git add .config/mango/bind.conf
git commit -m "feat(mango): add bind.conf with all keybindings ported from sway"
```

---

### Task 7: Write config.conf (main)

**Files:**
- Create: `.config/mango/config.conf`

- [ ] Write `config.conf`

```conf
# =============================================================================
# Mango WM Main Configuration
# =============================================================================

# Source sub-configs
source=~/.config/mango/env.conf
source=~/.config/mango/input.conf
source=~/.config/mango/monitor.conf
source=~/.config/mango/bind.conf
source=~/.config/mango/rule.conf
source=~/.config/mango/tag.conf

# =============================================================================
# Window Effects
# =============================================================================

# Blur
blur=1
blur_layer=1
blur_optimized=1
blur_params_num_passes=2
blur_params_radius=5
blur_params_noise=0.02
blur_params_brightness=0.9
blur_params_contrast=0.9
blur_params_saturation=1.2

# Shadows
shadows=1
layer_shadows=1
shadow_only_floating=0
shadows_size=10
shadows_blur=15
shadows_position_x=0
shadows_position_y=0
shadowscolor=0x0000007f

# Corner Radius
border_radius=10
no_radius_when_single=0

# Opacity
focused_opacity=1.0
unfocused_opacity=0.9

# =============================================================================
# Animations
# =============================================================================

animations=1
layer_animations=1
animation_type_open=slide
animation_type_close=slide
animation_fade_in=1
animation_fade_out=1
tag_animation_direction=1
zoom_initial_ratio=0.4
zoom_end_ratio=0.8
fadein_begin_opacity=0.5
fadeout_begin_opacity=0.8
animation_duration_move=500
animation_duration_open=400
animation_duration_tag=350
animation_duration_close=800
animation_duration_focus=0
animation_curve_open=0.46,1.0,0.29,1
animation_curve_move=0.46,1.0,0.29,1
animation_curve_tag=0.46,1.0,0.29,1
animation_curve_close=0.08,0.92,0,1
animation_curve_focus=0.46,1.0,0.29,1

# =============================================================================
# Layout Settings
# =============================================================================

# Scroller
scroller_structs=20
scroller_default_proportion=0.8
scroller_focus_center=0
scroller_prefer_center=0
edge_scroller_pointer_focus=1
scroller_default_proportion_single=1.0
scroller_proportion_preset=0.5,0.8,1.0

# Master-Stack
new_is_master=1
default_mfact=0.55
default_nmaster=1
smartgaps=1

# Dwindle
dwindle_smart_split=0
dwindle_drop_simple_split=1
dwindle_manual_split=0
dwindle_hsplit=1
dwindle_vsplit=1
dwindle_preserve_split=0

# Overview
hotarea_size=10
enable_hotarea=0
ov_tab_mode=1
ov_no_resize=1
overviewgappi=5
overviewgappo=30

# =============================================================================
# Appearance
# =============================================================================

gappih=5
gappiv=5
gappoh=5
gappov=5
scratchpad_width_ratio=0.8
scratchpad_height_ratio=0.9
borderpx=2
no_border_when_single=1

# Colors
rootcolor=0x201b14ff
bordercolor=0x444444ff
dropcolor=0x8FBA7C55
splitcolor=0xEB441EFF
focuscolor=0xc9b890ff
maximizescreencolor=0x89aa61ff
urgentcolor=0xad401fff
scratchpadcolor=0x516c93ff
globalcolor=0xb153a7ff
overlaycolor=0x14a57cff

# =============================================================================
# Misc
# =============================================================================

cursor_size=24
drag_tile_to_tile=1
drag_tile_small=1
enable_floating_snap=0
snap_distance=30
focus_cross_monitor=0
focus_cross_tag=0
axis_bind_apply_timeout=100
idleinhibit_ignore_visible=0

# =============================================================================
# Layer Rules
# =============================================================================

layerrule=animation_type_open:zoom,animation_type_close:zoom,layer_name:rofi
layerrule=noanim:1,noblur:1,layer_name:selection

# =============================================================================
# Autostart
# =============================================================================

exec-once=~/.config/mango/autostart.sh
```

- [ ] Verify config syntax

```bash
mango -c /home/zeyad/dotfiles/.config/mango/config.conf -p
```

Expected: no errors (may show warnings for sourced files that don't exist yet — that's fine until stow links them)

- [ ] Commit

```bash
git add .config/mango/config.conf
git commit -m "feat(mango): add main config.conf with visuals, animations, colors"
```

---

### Task 8: Write autostart.sh

**Files:**
- Create: `.config/mango/autostart.sh`

- [ ] Write `autostart.sh`

```bash
#!/usr/bin/env bash
# Mango autostart — runs once on startup via exec-once

# Polkit authentication agent
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &

# GNOME keyring
gnome-keyring-daemon --start --components=secrets,ssh &

# Kanshi (monitor management)
kanshi &

# Idle management
swayidle -w before-sleep "$HOME/.local/bin/lock-if-not-running.sh" &

# Desktop notifications
swaync &

# On-screen display for volume/brightness
swayosd-server &

# Clipboard history (text + images)
wl-paste --type text --watch cliphist store &
wl-paste --type image --watch cliphist store &

# Network applet
nm-applet --indicator &

sleep 2 && firewall-applet &

# App launcher drawer
nwg-drawer -r -term wezterm -c 6 -is 48 -mb 15 -ml 18 -mr 18 -mt 15 &

# ProtonVPN tray
protonvpn-app &

# Wallpaper (via Azote wrapper)
~/.azotebg &

wait
```

- [ ] Make executable

```bash
chmod +x /home/zeyad/dotfiles/.config/mango/autostart.sh
```

- [ ] Commit

```bash
git add .config/mango/autostart.sh
git commit -m "feat(mango): add autostart.sh for startup applications"
```

---

### Task 9: Update Waybar config for Mango compatibility

**Files:**
- Modify: `.config/waybar/config`

**Note:** We only change the modules that use Sway IPC. Create an alternate version or use conditional modules. Since Waybar doesn't support per-session config natively, we'll use a wrapper approach.

Actually, a better approach: create a separate waybar config for mango and launch the correct one via autostart.

Wait — looking at the waybar config, the `sway/workspaces` and `sway/language` modules talk to Sway IPC and won't work with Mango. Let's create a Mango-compatible waybar config.

**Option:** Create `.config/waybar/config-mango` and have `autostart.sh` launch `waybar -c ~/.config/waybar/config-mango`.

- [ ] Write `.config/waybar/config-mango` based on current `config`, with Sway-specific modules replaced

Copy the current `config` and make these changes:
1. Replace `sway/workspaces` with `wlr/workspaces`
2. Remove `sway/mode`
3. Replace `sway/language` with a custom script using `mmsg`
4. Keep `sway/window` (it uses wlr-foreign-toplevel-management and should work)
5. Keep all other modules unchanged

```bash
cp /home/zeyad/dotfiles/.config/waybar/config /home/zeyad/dotfiles/.config/waybar/config-mango
```

- [ ] Edit `.config/waybar/config-mango` — replace workspace module

Change:
```json
    "modules-left": [
        "custom/launcher",
        "sway/workspaces",
        "sway/mode",
        "sway/window"
    ],
```

To:
```json
    "modules-left": [
        "custom/launcher",
        "wlr/workspaces",
        "sway/window"
    ],
```

- [ ] Edit `.config/waybar/config-mango` — replace language module

Change:
```json
    "sway/language": {
        "format": "{}",
        "format-en": "🇺🇸",
        "format-ar": "🇪🇬",
        "on-click": "~/.local/bin/switch-layout.sh"
    },
```

To:
```json
    "custom/keyboard_layout": {
        "format": "{}",
        "exec": "mmsg get keyboardlayout 2>/dev/null | cut -d' ' -f4 || echo 'us'",
        "interval": 1,
        "on-click": "mmsg dispatch switch_keyboard_layout"
    },
```

- [ ] Update `autostart.sh` to use the mango-specific waybar config

Change:
```bash
# (remove nwg-drawer since Mango uses it via keybind)
```

And add before the `wait`:
```bash
# Start Waybar with mango config
waybar -c ~/.config/waybar/config-mango &
```

- [ ] Commit

```bash
git add .config/waybar/config-mango .config/mango/autostart.sh
git commit -m "feat(mango): add waybar config-mango with wlr modules for mango"
```

---

### Task 10: Update install.sh — add mango to dependency check

**Files:**
- Modify: `install.sh`

- [ ] Edit `install.sh` — add `mango` to the dependency list

Change line 39:
```bash
for cmd in nvim zsh tmux wezterm git lazygit fzf zoxide bat eza yazi; do
```

To:
```bash
for cmd in nvim zsh tmux wezterm git lazygit fzf zoxide bat eza yazi mango; do
```

- [ ] Commit

```bash
git add install.sh
git commit -m "chore: add mango to install.sh dependency check"
```

---

### Task 11: Run stow and verify

- [ ] Run stow to link everything

```bash
cd /home/zeyad/dotfiles && stow --restow --target "$HOME" .
```

- [ ] Verify config was linked

```bash
ls -la ~/.config/mango/
ls -la ~/.config/waybar/config-mango
```

Expected: all files exist and are symlinks to `~/dotfiles/.config/mango/*`

- [ ] Validate mango config syntax

```bash
mango -c ~/.config/mango/config.conf -p
```

Expected: no errors

- [ ] Commit final changes

```bash
git add -A
git commit -m "chore: stow links for mango config"
```

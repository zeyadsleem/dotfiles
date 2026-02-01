# Dotfiles

A modern, cohesive Linux desktop environment based on Sway (Wayland) with macOS-like workflow.

## Features

- **Window Manager**: Sway (i3-like tiling for Wayland)
- **Terminal**: Wezterm with JetBrainsMono Nerd Font
- **Editor**: Neovim (CLI) / xed (GUI)
- **Image Viewer**: Loupe (GNOME Image Viewer)
- **File Manager**: Thunar
- **Browser**: Brave
- **Launcher**: Fuzzel + nwg-drawer
- **Notifications**: Swaync
- **Screenshots**: macOS-style workflow with auto-save

## Screenshot Workflow

| Key | Action |
|-----|--------|
| `Print` | Select area → auto-save + clipboard |
| `Shift+Print` | Full screen → auto-save + clipboard |
| `Ctrl+Print` | Window → auto-save + clipboard |
| `Alt+Print` | Select area → open in swappy (annotation) |

Screenshots saved to: `~/Pictures/Screenshots/`

## Keybindings

### Basics
- `Mod+Return` - Terminal
- `Mod+d` - Fuzzel launcher
- `Mod+Shift+d` - nwg-drawer
- `Mod+q` - Close window
- `Mod+f` - Fullscreen
- `Mod+Shift+space` - Toggle floating

### Navigation (Vim-style)
- `Mod+h/j/k/l` - Move focus
- `Mod+Shift+h/j/k/l` - Move window

### Workspaces
- `Mod+1-0` - Switch workspace
- `Mod+Shift+1-0` - Move window to workspace

### System
- `Mod+Shift+e` - Power menu
- `Mod+f1` - Lock screen (gtklock)
- `Mod+Shift+n` - Notifications center
- `Mod+c` - Clipboard history
- `Mod+i` - Color picker (hyprpicker)

## Installation

### Prerequisites
```bash
# Install stow
sudo pacman -S stow

# Clone repository
git clone https://github.com/zeyadsleem/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### Apply Dotfiles
```bash
# Remove any existing conflicting files, then:
stow --adopt .
```

### Required Packages
```bash
# Core
yay -S sway waybar wezterm thunar brave fuzzel nwg-drawer

# Notifications & Clipboard
yay -S swaync cliphist wl-clipboard

# Screenshots
yay -S grim slurp swappy

# Image Viewer
yay -S loupe

# Tools
yay -S hyprpicker gtklock swayosd

# Terminal tools
yay -S zoxide fzf fd eza bat delta

# Development
yay -S neovim lazygit git
```

### Post-Installation

1. **Install packages** (see above)
2. **Reload Sway**: `swaymsg reload` or log out/in
3. **Test screenshots**: Press `Print` key
4. **Install Loupe**: `yay -S loupe`

## Structure

```
.
├── .config/
│   ├── nvim/           # Neovim config (LazyVim)
│   ├── sway/           # Sway WM config
│   ├── waybar/         # Status bar
│   ├── swaync/         # Notifications
│   ├── wezterm/        # Terminal config
│   └── ...
├── .zshrc              # Zsh configuration
└── README.md           # This file
```

## Default Applications

- **Text/Code**: nvim
- **Images**: Loupe
- **PDF**: Atril
- **Videos**: Celluloid
- **Archives**: File Roller

## Tips

- Use `stow .` to apply changes after editing dotfiles
- Screenshots automatically copy to clipboard
- Clipboard history available with `Mod+c`
- Color picker copies hex code with `Mod+i`

## License

MIT - Do whatever you want!

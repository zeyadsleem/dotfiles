#!/bin/bash
# Setup script for dotfiles
# Run this after cloning the repository

set -e

echo "🚀 Setting up dotfiles..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    echo -e "${YELLOW}Installing stow...${NC}"
    sudo pacman -S stow
fi

echo -e "${GREEN}✓ Stow is installed${NC}"

# Check for conflicts and remove them
echo -e "${YELLOW}Checking for conflicts...${NC}"
CONFLICTS=$(stow . 2>&1 | grep "existing target" | awk '{print $NF}' || true)

if [ -n "$CONFLICTS" ]; then
    echo -e "${YELLOW}Found conflicts, removing...${NC}"
    for file in $CONFLICTS; do
        rm -f "$HOME/$file"
        echo "  Removed: $file"
    done
fi

# Apply dotfiles
echo -e "${YELLOW}Applying dotfiles with stow...${NC}"
stow --adopt .
echo -e "${GREEN}✓ Dotfiles applied${NC}"

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p ~/Pictures/Screenshots
echo -e "${GREEN}✓ Directories created${NC}"

# Check for required packages
echo -e "${YELLOW}Checking required packages...${NC}"

PACKAGES=(
    # Core
    "sway" "waybar" "wezterm" "thunar" "fuzzel" "nwg-drawer"
    # Notifications & Clipboard
    "swaync" "cliphist" "wl-clipboard"
    # Screenshots
    "grim" "slurp" "swappy"
    # Image Viewer
    "loupe"
    # Tools
    "hyprpicker" "gtklock" "swayosd" "polkit-gnome"
    # Terminal tools
    "zoxide" "fzf" "fd" "eza" "bat" "delta"
    # Development
    "neovim" "lazygit" "git" "jq"
)

MISSING=()
for pkg in "${PACKAGES[@]}"; do
    if ! pacman -Q "$pkg" &> /dev/null; then
        MISSING+=("$pkg")
    fi
done

if [ ${#MISSING[@]} -eq 0 ]; then
    echo -e "${GREEN}✓ All packages are installed${NC}"
else
    echo -e "${YELLOW}Missing packages:${NC}"
    printf '  %s\n' "${MISSING[@]}"
    echo ""
    echo -e "${YELLOW}Install with:${NC}"
    echo "yay -S ${MISSING[*]}"
fi

echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Install missing packages (if any)"
echo "  2. Log out and log back in to Sway"
echo "  3. Test screenshots with Print key"
echo ""
echo "Keybindings:"
echo "  Print        - Screenshot selection"
echo "  Shift+Print  - Screenshot full screen"
echo "  Ctrl+Print   - Screenshot window"
echo "  Mod+d        - Open launcher"
echo "  Mod+Return   - Open terminal"

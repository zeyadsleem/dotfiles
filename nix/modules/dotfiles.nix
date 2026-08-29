{ config, lib, dotfilesDir, ... }:
{
  home.file = {
    # --- Wayland compositor + friends (Layer 2: config managed, binary stays pacman) ---
    # NOTE: niri linked per-file ONLY (config.kdl). ~/.config/niri is a real dir with
    # local extras (config.kdl.bak*, fix-greetd-keyring.sh, fix-pam-only.sh,
    # restore-greetd.sh) that are NOT in the repo — a whole-dir symlink would orphan them.
    ".config/niri/config.kdl" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/niri/config.kdl";
    };
    # NOTE: waybar/swaync/gtklock linked per-file — their real dirs hold runtime-created
    # content NOT in repo (waybar/scripts, colors.css, gtklock/*.png, style.css) that a
    # whole-dir symlink would orphan. Per-file links match stow's exact on-disk behavior.
    ".config/waybar/config-niri" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/waybar/config-niri";
    };
    ".config/waybar/style.css" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/waybar/style.css";
    };
    ".config/swaync/config.json" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/swaync/config.json";
    };
    ".config/kanshi" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/kanshi";
    };
    ".config/swayosd" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/swayosd";
    };
    ".config/gtklock/config.ini" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/gtklock/config.ini";
    };

    # --- GTK / theme-facing config (mutated by set-theme at runtime) ---
    # gtk-3.0 linked per-file: local dir holds runtime-created `bookmarks` not in repo.
    ".config/gtk-3.0/settings.ini" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/gtk-3.0/settings.ini";
    };
    ".config/themes" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/themes";
    };

    # --- Apps (config managed, binaries stay pacman) ---
    # Thunar/fastfetch/swappy/lazygit are REAL DIRs on disk; link per-file (stow-equivalent)
    # so any runtime-created content in those dirs is never orphaned.
    ".config/Thunar/accels.scm" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/Thunar/accels.scm";
    };
    ".config/Thunar/uca.xml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/Thunar/uca.xml";
    };
    ".config/fastfetch/config.jsonc" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/fastfetch/config.jsonc";
    };
    ".config/swappy/config" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/swappy/config";
    };
    ".config/lazygit/config.yml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/lazygit/config.yml";
    };
    ".config/ripgrep" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/ripgrep";
    };
    ".config/tmux" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/tmux";
    };
    ".config/mimeapps.list" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/mimeapps.list";
    };
    ".config/brave-flags.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/brave-flags.conf";
    };
    ".config/xed.dconf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/xed.dconf";
    };

    # --- Home-level dotfiles not managed by a programs.* module ---
    ".face" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.face";
    };
    ".gtkrc-2.0" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.gtkrc-2.0";
    };
    ".vimrc" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.vimrc";
    };
    ".icons" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.icons";
    };
  };
}
{
  config,
  lib,
  dotfilesDir,
  ...
}:
{
  home.file = {
    # --- Wayland compositor + friends (Layer 2: config managed, binary stays pacman) ---
    # NOTE: niri linked per-file ONLY (config.kdl). ~/.config/niri is a real dir with
    # local extras (config.kdl.bak*, fix-greetd-keyring.sh, fix-pam-only.sh,
    # restore-greetd.sh) that are NOT in the repo — a whole-dir symlink would orphan them.
    ".config/niri/config.kdl" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/niri/config.kdl";
    };

    # Noctalia owns the shell layer. Keep config.toml linked per-file: the real
    # ~/.config/noctalia directory also holds runtime palettes and templates.
    ".config/noctalia/config.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/noctalia/config.toml";
    };

    # Output profiles stay with kanshi; Noctalia does not manage outputs.
    ".config/kanshi" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/kanshi";
    };

    # --- GTK / theme-facing config (Noctalia templates write gtk.css alongside) ---
    # gtk-3.0 linked per-file: local dir holds runtime-created `bookmarks` not in repo.
    ".config/gtk-3.0/settings.ini" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/gtk-3.0/settings.ini";
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
    # Herdr keeps logs, sockets, and session.json next to its config in the
    # real ~/.config/herdr dir, so link the config file only.
    ".config/herdr/config.toml" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/herdr/config.toml";
    };
    ".config/mimeapps.list" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/mimeapps.list";
    };
    # fontconfig: map Obsidian's default "Inter" to IBM Plex Sans Arabic
    # (Arabic + Latin in one voice; affects apps requesting Inter generically).
    ".config/fontconfig/fonts.conf" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/fontconfig/fonts.conf";
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

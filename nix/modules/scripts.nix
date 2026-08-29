{ config, lib, dotfilesDir, ... }:
{
  home.file = {
    # Layer 3: user scripts — symlinked into ~/.local/bin so they stay writable.
    # Only git-tracked scripts are managed; tools like bd/claude/codex/iii live on
    # disk outside the repo and are left untouched.
    # NOTE: no `executable = true` here on purpose. With out-of-store symlinks HM
    # builds the file with `cp`, which dereferences the symlink to the live repo
    # path outside the Nix store/sandbox and fails the build. The repo scripts
    # already carry +x on disk, so plain symlinks preserve executability.
    ".local/bin/arabic-time.py" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/arabic-time.py";
    };
    ".local/bin/disable-pbtn-wake.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/disable-pbtn-wake.sh";
    };
    ".local/bin/editor-config" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/editor-config";
    };
    ".local/bin/emoji-picker" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/emoji-picker";
    };
    ".local/bin/force-suspend.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/force-suspend.sh";
    };
    ".local/bin/hijri-date.py" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/hijri-date.py";
    };
    ".local/bin/lock-if-not-running.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/lock-if-not-running.sh";
    };
    ".local/bin/power-menu-niri.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/power-menu-niri.sh";
    };
    ".local/bin/set-theme" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/set-theme";
    };
    ".local/bin/set-theme-picker" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/set-theme-picker";
    };
    ".local/bin/set-wallpaper" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/set-wallpaper";
    };
    ".local/bin/switch-layout.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/switch-layout.sh";
    };
    ".local/bin/theme-info" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/theme-info";
    };
    ".local/bin/tmux-cht.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/tmux-cht.sh";
    };
    ".local/bin/tmux-session-wizard.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.local/bin/tmux-session-wizard.sh";
    };
  };
}
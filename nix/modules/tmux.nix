{ config, lib, dotfilesDir, ... }:
{
  home.file.".tmux.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.tmux.conf";
  };
}
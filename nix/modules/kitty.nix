{ config, lib, dotfilesDir, ... }:
{
  home.file.".config/kitty/kitty.conf" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/kitty/kitty.conf";
  };
}
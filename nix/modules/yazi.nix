{ config, lib, dotfilesDir, ... }:
{
  home.file.".config/yazi" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/yazi";
  };
}
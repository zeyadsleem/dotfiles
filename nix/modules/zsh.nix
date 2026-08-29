{ config, lib, dotfilesDir, ... }:
{
  home.file.".zshrc" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.zshrc";
  };
  home.file.".p10k.zsh" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.p10k.zsh";
  };
  home.file.".alias.zsh" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.alias.zsh";
  };
}
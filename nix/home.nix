{ config, pkgs, ... }:

{
  home.username = "zeyad";
  home.homeDirectory = "/home/zeyad";
  home.stateVersion = "24.05";

  imports = [
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/tmux.nix
    ./modules/zsh.nix
    ./modules/kitty.nix
    ./modules/yazi.nix
    ./modules/dotfiles.nix
    ./modules/scripts.nix
  ];

  programs.home-manager.enable = true;
}
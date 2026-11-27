{ config, ... }:

{
  # Single source of truth for the repo location: derived from the configured
  # home directory (the repo is always cloned at ~/dotfiles).
  _module.args.dotfilesDir = config.home.homeDirectory + "/dotfiles";

  home = {
    username = "zeyad";
    homeDirectory = "/home/zeyad";
    stateVersion = "24.05";
  };

  imports = [
    ./modules/packages.nix
    ./modules/git.nix
    ./modules/zsh.nix
    ./modules/kitty.nix
    ./modules/konsole.nix
    ./modules/yazi.nix
    ./modules/dotfiles.nix
  ];

  programs.home-manager.enable = true;
}

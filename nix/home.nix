{ config, pkgs, ... }:

{
  home.username = "zeyad";
  home.homeDirectory = "/home/zeyad";
  home.stateVersion = "24.05";

  home.packages = with pkgs; [
    git
    neovim
    ripgrep
    fd
    fzf
    zoxide
    eza
    bat
    tmux
    jq
    yq
    htop
    tree
    unzip
    direnv
    starship
  ];

  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.home-manager.enable = true;
}

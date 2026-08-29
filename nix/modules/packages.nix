{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    neovim
    ripgrep
    fd
    zoxide
    eza
    bat
    tmux
    lazygit
    delta
    jq
    yq
    htop
    btop
    tree
    unzip
    starship
  ];
}
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    neovim
    nil
    nixfmt-rfc-style
    statix
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
  ];
}

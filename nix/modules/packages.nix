{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    neovim
    nil
    nixfmt
    statix
    ripgrep
    fd
    zoxide
    eza
    bat
    libnotify
    lazygit
    delta
    jq
    htop
    btop
    tree
    unzip
    ffmpeg
    yt-dlp
    mypy
    traceroute
    yq-go
  ];
}

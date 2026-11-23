{ pkgs, ... }:
let
  # Ptyxis 50.1 always draws its libadwaita header bar and tab bar. Kitty runs
  # with hidden decorations and a hidden tab bar, so patch them out and use
  # kitty's 3px terminal padding.
  ptyxis = pkgs.ptyxis.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./ptyxis-hide-headerbar.patch
    ];
  });
in
{
  home.packages = with pkgs; [
    git
    neovim
    ptyxis
    nil
    nixfmt-rfc-style
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

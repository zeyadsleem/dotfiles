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
    # Upstream Linux binary; this nixpkgs revision does not package workmux yet.
    (stdenvNoCC.mkDerivation {
      pname = "workmux";
      version = "0.1.269";
      src = fetchurl {
        url = "https://github.com/raine/workmux/releases/download/v0.1.269/workmux-linux-amd64.tar.gz";
        hash = "sha256-wbTvi0DTjgORB2AzQwHMHcd++VFFzYicw7xOVzVovhs=";
      };
      sourceRoot = ".";
      dontConfigure = true;
      dontBuild = true;
      installPhase = ''
        runHook preInstall
        install -Dm755 workmux "$out/bin/workmux"
        runHook postInstall
      '';
      meta.platforms = [ "x86_64-linux" ];
    })
    libnotify
    lazygit
    delta
    jq
    yq
    htop
    btop
    tree
    unzip
    ffmpeg
    yt-dlp
    antigravity
  ];
}

{ pkgs, ... }:
let
  # Konsole cannot be told to hide its menubar, tabbar and toolbar through
  # konsolerc: it rewrites that file on exit, and neither the config keys nor
  # konsolestaterc win over the window's own chrome. CLI flags are the only
  # reliable switch, so ship a wrapper instead of managing Konsole's state.
  konsole = pkgs.writeShellScriptBin "konsole" ''
    exec ${pkgs.kdePackages.konsole}/bin/konsole \
      --profile noctalia \
      --hide-menubar --hide-tabbar --hide-toolbars "$@"
  '';
in
{
  # Konsole is the default terminal: it renders kitty-graphics images (yazi
  # previews, herdr panes) and, through Qt/fribidi, bidi Arabic as well as
  # ptyxis did.
  home.packages = [
    pkgs.kdePackages.konsole
  ];

  # ~/.local/bin precedes every other PATH entry in both niri and zsh, so
  # `konsole` and $TERMINAL resolve to the wrapper. The real binary remains
  # reachable as ${pkgs.kdePackages.konsole}/bin/konsole for debugging.
  home.file.".local/bin/konsole" = {
    source = "${konsole}/bin/konsole";
  };
}

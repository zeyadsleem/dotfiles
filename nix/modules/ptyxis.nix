{ ... }:
let
  # Fixed UUID so the managed profile stays the same across generations.
  # dconf paths are /org/gnome/Ptyxis/Profiles/<uuid>/ (org.gnome.Ptyxis.Profile).
  profileUuid = "6f2c9a41-8d3b-4e57-9c1a-2b7d4e6f8a90";
in
{
  # Ptyxis has no bidi switch: VTE enables implicit bidi (BDSM mode 8) by
  # default with an LTR paragraph direction, which is exactly what we want
  # for mixed Arabic/English terminal output. This module only configures
  # look and feel; the bidi behaviour comes from VTE.
  dconf.settings = {
    "org/gnome/Ptyxis" = {
      default-profile-uuid = profileUuid;
      profile-uuids = [ profileUuid ];

      # Match kitty: Maple Mono NF at ~11.3pt, dark UI, no session restore.
      use-system-font = false;
      font-name = "Maple Mono NF Medium 11.3";
      interface-style = "dark";
      cursor-shape = "block";
      cursor-blink-mode = "on";
      restore-session = false;
      restore-window-size = true;
      prompt-on-close = false;
      scrollbar-policy = "never";
      # Both bell types default to true in Ptyxis; keep them off.
      audible-bell = false;
      visual-bell = false;
      toast-on-copy-clipboard = true;
    };

    "org/gnome/Ptyxis/Profiles/${profileUuid}" = {
      label = "Default";
      palette = "noctalia";
      opacity = 0.9;
      login-shell = false;
      limit-scrollback = true;
      scrollback-lines = 10000;
      bold-is-bright = false;
      # Kitty: modify_font cell_height 115%, cell_width 105%.
      cell-height-scale = 1.15;
      cell-width-scale = 1.05;
      cjk-ambiguous-width = "narrow";
      preserve-directory = "safe";
    };
  };
}

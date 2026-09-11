{
  description = "Zeyad Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-desktop-linux.url = "github:ilysenko/codex-desktop-linux";
  };

  outputs =
    { nixpkgs, home-manager, codex-desktop-linux, ... }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      homeConfigurations.zeyad = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./home.nix

          codex-desktop-linux.homeManagerModules.default

          {
            programs.codexDesktopLinux = {
              enable = true;
              package =
                codex-desktop-linux.packages.${system}.codex-desktop;
            };

            home.sessionVariables.CODEX_OZONE_PLATFORM = "wayland";
          }
        ];
      };
    };
}

{
  description = "Home Manager configuration using Nix Flakes";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      # `antigravity` is an unfree IDE and is declared in nix/modules/packages.nix,
      # so the configuration can only evaluate when that one package is allowed.
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfreePredicate =
          pkg: builtins.elem (nixpkgs.lib.getName pkg) [ "antigravity-ide" ];
      };
    in
    {
      homeConfigurations."zeyad" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        extraSpecialArgs = {
          dotfilesDir = "/home/zeyad/dotfiles";
        };

        modules = [
          ./nix/home.nix
        ];
      };
    };
}

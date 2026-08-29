{
  description = "Home Manager configuration using Nix Flakes";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations."zeyad" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ({ config, ... }: {
            _module.args.dotfilesDir = config.home.homeDirectory + "/dotfiles";
          })
          ./nix/home.nix
        ];
      };
    };
}
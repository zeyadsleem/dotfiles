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
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      homeConfigurations."zeyad" = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          ./nix/home.nix
        ];
      };

      # Pinned CLI: install.sh and the shell helpers run this instead of
      # home-manager/master, so the binary always matches flake.lock.
      packages.${system}.home-manager = home-manager.packages.${system}.home-manager;

      # Backs `.envrc` (`use flake`).
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.nil
          pkgs.nixfmt
          pkgs.statix
        ];
      };
    };
}

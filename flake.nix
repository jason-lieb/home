{
  description = "Jason's NixOS and Home Manager configurations";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, nixpkgs-unstable, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
      };
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config = { allowUnfree = true; };
      };
    in {
      nixosConfigurations = {
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./desktop.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.jason = { config, pkgs, ... }: {
                imports = [
                  (import ./home.nix { inherit config pkgs pkgs-unstable; })
                ];
              };
            }
          ];
          specialArgs = { inherit pkgs-unstable; };
        };
        chromebook = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./chromebook.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.jason = { config, pkgs, ... }: {
                imports = [
                  (import ./home.nix { inherit config pkgs pkgs-unstable; })
                ];
              };
            }
          ];
          specialArgs = { inherit pkgs-unstable; };
        };
      };
    };
}

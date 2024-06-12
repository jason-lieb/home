{
  description = "Jason's NixOS and Home Manager configurations";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-stable";
    freckle.url = "github:freckle/flakes?dir=main";
  };

  outputs = inputs:
    let
      system = "x86_64-linux";
      nixpkgsConfig = {
        inherit system;
        config.allowUnfree = true;
      };
      mkNixos = hostname:
        let
          pkgs = import inputs.nixpkgs-stable nixpkgsConfig;
          pkgs-unstable = import inputs.nixpkgs-unstable nixpkgsConfig;
        in inputs.nixpkgs-stable.lib.nixosSystem {
          inherit system;
          modules = [
            ./${hostname}
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.users.jason = { config, pkgs, ... }: {
                imports = [
                  (import ./common/home.nix {
                    inherit config pkgs pkgs-unstable;
                  })
                ];
              };
            }
          ];
          specialArgs = { inherit pkgs-unstable; };
        };
    in {
      nixosConfigurations = {
        desktop = mkNixos "desktop";
        chromebook = mkNixos "chromebook";
      };
    };
}

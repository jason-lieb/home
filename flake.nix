{
  description = "Jason's NixOS and Home Manager configurations";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    # nixos-cosmic = {
    #   url = "github:lilyinstarlight/nixos-cosmic";
    #   inputs.nixpkgs.follows = "nixpkgs-stable";
    # };
    freckle.url = "github:freckle/flakes?dir=main";
  };

  outputs =
    inputs:
    let
      system = "x86_64-linux";
      nixpkgsConfig = {
        inherit system;
        config.allowUnfree = true;
      };
      mkNixos =
        hostname:
        let
          pkgs = import inputs.nixpkgs-stable nixpkgsConfig;
          pkgs-unstable = import inputs.nixpkgs-unstable nixpkgsConfig;
          vscode-extensions = inputs.nix-vscode-extensions.extensions.x86_64-linux;
          specialArgs = {
            inherit pkgs-unstable;
          };
        in
        inputs.nixpkgs-stable.lib.nixosSystem {
          inherit system;
          inherit specialArgs;
          modules = [
            (import ./nixos { inherit pkgs hostname; })
            # inputs.nixos-cosmic.nixosModules.default
            inputs.freckle.nixosModules.docker-for-local-dev
            inputs.freckle.nixosModules.renaissance-vpn
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.backupFileExtension = ".backup";
              home-manager.users.jason =
                { config, pkgs, ... }:
                {
                  imports = [
                    (import ./home {
                      inherit
                        config
                        pkgs
                        pkgs-unstable
                        vscode-extensions
                        ;
                    })
                  ];
                };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        desktop = mkNixos "desktop";
        laptop = mkNixos "laptop";
        chromebook = mkNixos "chromebook";
      };
    };
}

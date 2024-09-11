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
    {
      self,
      nixpkgs-stable,
      nixpkgs-unstable,
      nix-vscode-extensions,
      home-manager,
      freckle,
    }:
    let
      system = "x86_64-linux";
      nixpkgsConfig = {
        inherit system;
        config.allowUnfree = true;
      };
      vscode-extensions = nix-vscode-extensions.extensions.${system};
      pkgs = import nixpkgs-stable nixpkgsConfig;
      pkgs-unstable = import nixpkgs-unstable nixpkgsConfig;

      mkNixos =
        hostname:
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit pkgs-unstable;
          };
          modules = [
            (import ./nixos { inherit hostname pkgs; })
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.backupFileExtension = ".backup";
              home-manager.users.jason =
                { pkgs, ... }:
                {
                  imports = [
                    (import ./home {
                      inherit
                        system
                        pkgs
                        freckle
                        vscode-extensions
                        ;
                      home-manager = false;
                    })
                  ];
                };
            }
            # nixos-cosmic.nixosModules.default
            freckle.nixosModules.docker-for-local-dev
            freckle.nixosModules.renaissance-vpn
          ];
        };

      mkHome = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          (import ./home {
            inherit pkgs freckle vscode-extensions;
            home-manager = true;
          })
        ];
      };
    in
    {
      nixosConfigurations = {
        desktop = mkNixos "desktop";
        laptop = mkNixos "laptop";
        chromebook = mkNixos "chromebook";
      };
      homeConfigurations = {
        "jason@debian" = mkHome;
      };
    };
}

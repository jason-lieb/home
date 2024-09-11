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
    # nix-darwin.url = "github:LnL7/nix-darwin";
    # nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # homebrew-bundle = {
    #   url = "github:homebrew/homebrew-bundle";
    #   flake = false;
    # };
    # homebrew-core = {
    #   url = "github:homebrew/homebrew-core";
    #   flake = false;
    # };
    # homebrew-cask = {
    #   url = "github:homebrew/homebrew-cask";
    #   flake = false;
    # };
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
      pkgs = import nixpkgs-stable nixpkgsConfig;
      pkgs-unstable = import nixpkgs-unstable nixpkgsConfig;
      vscode-extensions = nix-vscode-extensions.extensions.${system};

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
              home-manager.backupFileExtension = ".bak";
              home-manager.users.jason =
                { pkgs, ... }:
                {
                  imports = [
                    (import ./home {
                      is-home-manager = false;
                      inherit
                        system
                        pkgs
                        freckle
                        vscode-extensions
                        ;
                    })
                  ];
                };
            }
            # nixos-cosmic.nixosModules.default
            freckle.nixosModules.docker-for-local-dev
            freckle.nixosModules.renaissance-vpn
          ];
        };

      # mkDarwin =
      #   hostname:
      #   nix-darwin.lib.darwinSystem {
      #     specialArgs = {
      #       inherit self keys username;
      #     };
      #     modules = [
      #       home-manager.darwinModules.home-manager
      #       homeManagerConfig
      #       nix-homebrew.darwinModules.nix-homebrew
      #       {
      #         nix-homebrew = {
      #           enable = true;
      #           enableRosetta = false;
      #           user = username;
      #           taps = {
      #             "homebrew/homebrew-bundle" = homebrew-bundle;
      #             "homebrew/homebrew-core" = homebrew-core;
      #             "homebrew/homebrew-cask" = homebrew-cask;
      #           };
      #           mutableTaps = false;
      #         };
      #       }
      #     ];
      #   };

      mkHome = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          (import ./home {
            is-home-manager = true;
            inherit
              system
              pkgs
              freckle
              vscode-extensions
              ;
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
      # darwinConfigurations = {
      #   mac = mkDarwin "JLIEB0523-MB";
      # };
    };
}

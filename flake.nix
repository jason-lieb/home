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
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
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
      nix-darwin,
      nix-homebrew,
      homebrew-bundle,
      homebrew-core,
      homebrew-cask,
      home-manager,
      freckle,
    }:
    let

      mkPackages = system: rec {
        nixpkgsConfig = {
          inherit system;
          config.allowUnfree = true;
        };
        pkgs = import nixpkgs-stable nixpkgsConfig;
        pkgs-unstable = import nixpkgs-unstable nixpkgsConfig;
        vscode-extensions = nix-vscode-extensions.extensions.${system};
      };

      mkHomeManagerConfig =
        system:
        let
          packages = mkPackages system;
          vscode-extensions = packages.vscode-extensions;
        in
        {
          home-manager.useGlobalPkgs = true;
          home-manager.backupFileExtension = ".bak";
          home-manager.users.jason =
            { pkgs, ... }:
            {
              imports = [
                (import ./home {
                  is-not-nixos = false;
                  inherit
                    system
                    pkgs
                    freckle
                    vscode-extensions
                    ;
                })
              ];
            };
        };

      mkNixos =
        hostname:
        let
          system = "x86_64-linux";
          packages = mkPackages system;
          pkgs = packages.pkgs;
        in
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          modules = [
            (import ./nixos { inherit hostname pkgs; })
            home-manager.nixosModules.home-manager
            (mkHomeManagerConfig system)
            # nixos-cosmic.nixosModules.default
            freckle.nixosModules.docker-for-local-dev
            freckle.nixosModules.renaissance-vpn
          ];
        };

      mkDarwin =
        hostname:
        let
          system = "aarch64-darwin";
        in
        nix-darwin.lib.darwinSystem {
          modules = [
            ./macbook
            home-manager.darwinModules.home-manager
            (mkHomeManagerConfig system)
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                enableRosetta = false;
                user = "jason.lieb";
                taps = {
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                };
                mutableTaps = false;
              };
            }
          ];
        };

      mkHome =
        let
          system = "x86_64-linux";
          packages = mkPackages system;
          pkgs = packages.pkgs;
          vscode-extensions = packages.vscode-extensions;
        in
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            (import ./home {
              is-not-nixos = true;
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

      darwinConfigurations = {
        macbook = mkDarwin;
      };
      darwinPackages = self.darwinConfigurations.macbook.pkgs;

      nixConfig = {
        substituters = [
          "https://freckle.cachix.org"
          "https://freckle-private.cachix.org"
          "https://yazi.cachix.org"
          "https://cosmic.cachix.org/"
        ];

        trusted-public-keys = [
          "freckle.cachix.org-1:WnI1pZdwLf2vnP9Fx7OGbVSREqqi4HM2OhNjYmZ7odo="
          "freckle-private.cachix.org-1:zbTfpeeq5YBCPOjheu0gLyVPVeM6K2dc1e8ei8fE0AI="
          "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
          "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
        ];
      };
    };
}

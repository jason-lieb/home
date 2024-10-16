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
      # nixos-cosmic,
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
            inherit hostname pkgs;
          };
          modules = [
            ./nixos
            freckle.nixosModules.docker-for-local-dev
            freckle.nixosModules.renaissance-vpn
            # nixos-cosmic.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.backupFileExtension = ".bak";
              home-manager.users.jason.imports = [ ./home ];
              home-manager.extraSpecialArgs = {
                inherit
                  system
                  pkgs-unstable
                  vscode-extensions
                  freckle
                  ;
              };
            }
          ];
        };

    in
    {
      nixosConfigurations = {
        desktop = mkNixos "desktop";
        laptop = mkNixos "laptop";
      };

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

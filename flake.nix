{
  description = "Jason's NixOS and Home Manager configurations";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    # nixos-cosmic = {
    #   url = "github:lilyinstarlight/nixos-cosmic";
    #   inputs.nixpkgs.follows = "nixpkgs-stable";
    # };
    freckle.url = "github:freckle/flakes?dir=main";
    ghostty.url = "github:ghostty-org/ghostty";
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
      ghostty,
    }:
    let
      system = "x86_64-linux";
      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
      vscode-extensions = nix-vscode-extensions.extensions.${system};
      mkNixos =
        hostname:
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit
              self
              hostname
              ghostty
              ;
          };
          modules = [
            ./nixos
            # nixos-cosmic.nixosModules.default
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.backupFileExtension = "bak";
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
        z560 = mkNixos "z560";
      };

      nixConfig = {
        extra-substituters = [
          "https://ghostty.cachix.org"
          # "https://cosmic.cachix.org/"
        ];
        extra-trusted-public-keys = [
          "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
          # "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
        ];
      };
    };
}

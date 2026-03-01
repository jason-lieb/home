{
  description = "Jason's NixOS and Home Manager configurations";

  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs-stable";
      inputs.home-manager.follows = "home-manager";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    ghostty.url = "github:ghostty-org/ghostty";
    claude-code.url = "github:sadjow/claude-code-nix";
  };

  outputs =
    {
      self,
      nixpkgs-stable,
      nixpkgs-unstable,
      nix-vscode-extensions,
      home-manager,
      plasma-manager,
      nix-flatpak,
      ghostty,
      claude-code,
    }:
    let
      system = "x86_64-linux";

      pkgs-unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      mkNixos =
        hostname:
        nixpkgs-stable.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit self hostname ghostty;
          };
          modules = [
            ./nixos
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.backupFileExtension = "bak";
              home-manager.users.jason.imports = [
                ./home
                plasma-manager.homeModules.plasma-manager
                nix-flatpak.homeManagerModules.nix-flatpak
              ];
              home-manager.extraSpecialArgs = {
                inherit
                  hostname
                  pkgs-unstable
                  ;
                vscode-extensions = nix-vscode-extensions.extensions.${system};
                claude-code-pkg = claude-code.packages.${system}.default;
              };
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        desktop = mkNixos "desktop";
        laptop = mkNixos "laptop";
        mini = mkNixos "mini";
        z560 = mkNixos "z560";
      };

      nixConfig = {
        extra-substituters = [
          "https://ghostty.cachix.org"
        ];
        extra-trusted-public-keys = [
          "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
        ];
      };
    };
}

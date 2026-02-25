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
    nix-darwin = {
      url = "github:lnl7/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs-stable";
      inputs.home-manager.follows = "home-manager";
    };
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    freckle.url = "github:freckle/flakes?dir=main";
    ghostty.url = "github:ghostty-org/ghostty";
    claude-code.url = "github:sadjow/claude-code-nix";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs =
    {
      self,
      nixpkgs-stable,
      nixpkgs-unstable,
      nix-vscode-extensions,
      home-manager,
      nix-darwin,
      plasma-manager,
      nix-flatpak,
      freckle,
      ghostty,
      claude-code,
      llm-agents,
    }:
    let
      mkHomeManagerConfig =
        {
          system,
          hostname,
          username,
          isDarwin,
          hmImports,
        }:
        let
          pkgs-unstable = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          vscode-extensions = nix-vscode-extensions.extensions.${system};
          llm-agents-pkgs = llm-agents.packages.${system};
        in
        {
          home-manager.useGlobalPkgs = true;
          home-manager.backupFileExtension = "bak";
          home-manager.users.${username}.imports = hmImports;
          home-manager.extraSpecialArgs = {
            inherit
              system
              hostname
              username
              pkgs-unstable
              vscode-extensions
              freckle
              claude-code
              llm-agents-pkgs
              isDarwin
              ;
          };
        };

      mkNixos =
        hostname:
        nixpkgs-stable.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {
            inherit self hostname ghostty;
          };
          modules = [
            ./nixos
            home-manager.nixosModules.home-manager
            (mkHomeManagerConfig {
              system = "x86_64-linux";
              inherit hostname;
              username = "jason";
              isDarwin = false;
              hmImports = [
                ./home/linux
                plasma-manager.homeModules.plasma-manager
                nix-flatpak.homeManagerModules.nix-flatpak
              ];
            })
          ];
        };

      mkDarwin =
        hostname:
        let
          username = "jason.lieb";
        in
        nix-darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          specialArgs = {
            inherit self hostname ghostty username;
          };
          modules = [
            ./darwin
            home-manager.darwinModules.home-manager
            (mkHomeManagerConfig {
              system = "aarch64-darwin";
              inherit hostname username;
              isDarwin = true;
              hmImports = [
                ./home/darwin
              ];
            })
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
      darwinConfigurations = {
        work = mkDarwin "work";
      };

      nixConfig = {
        extra-substituters = [
          "https://ghostty.cachix.org"
          "https://cache.numtide.com"
        ];
        extra-trusted-public-keys = [
          "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
          "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
        ];
      };
    };
}

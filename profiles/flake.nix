{
  description = "Nixos Profiles for Global Tools";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    freckle.url = "github:freckle/flakes?dir=main";
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      freckle,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        fourmolu = freckle.packages.${system}.fourmolu-0-13-x;
        haskell =
          version:
          (freckle.lib.${system}.haskellBundle {
            ghcVersion = version;
            enableHLS = true;
          });
      in
      {
        packages = rec {
          default = backend;
          backend = pkgs.buildEnv {
            name = "backend";
            paths = [
              fourmolu
              (haskell "ghc-9-2-8")
            ];
          };
          curricula = pkgs.buildEnv {
            name = "curricula";
            paths = [
              fourmolu
              (haskell "ghc-9-6-6")
            ];
          };
        };
      }
    );

  nixConfig = {
    extra-substituters = [
      "https://freckle.cachix.org"
      "https://freckle-private.cachix.org"
    ];
    extra-trusted-public-keys = [
      "freckle.cachix.org-1:WnI1pZdwLf2vnP9Fx7OGbVSREqqi4HM2OhNjYmZ7odo="
      "freckle-private.cachix.org-1:zbTfpeeq5YBCPOjheu0gLyVPVeM6K2dc1e8ei8fE0AI="
    ];
  };
}

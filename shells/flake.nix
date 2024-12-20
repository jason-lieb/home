{
  description = "Unified shell for dev tools";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    educator.url = "github:freckle/megarepo?dir=frontend/educator";
    backend.url = "github:freckle/megarepo?dir=backend";
    curricula-api.url = "github:freckle/megarepo?dir=text-assets";
  };

  outputs =
    {
      flake-utils,
      nixpkgs,
      educator,
      backend,
      curricula-api,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        flakes = [
          educator
          backend
          curricula-api
        ];
        defaultShell = flake: flake.devShells.${system}.default;
        mkBuildInputs = flake: (defaultShell flake).buildInputs;
        mkNativeBuildInputs = flake: (defaultShell flake).nativeBuildInputs;
        mkShellHook = flake: (defaultShell flake).shellHook;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "unified-shell";
          buildInputs = builtins.concatLists (map mkBuildInputs flakes);
          nativeBuildInputs = builtins.concatLists (map mkNativeBuildInputs flakes);
          shellHook = builtins.concatStringsSep "\n" (map mkShellHook flakes);
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

{ config, pkgs, pkgs-unstable, ... }:

{
  home.username = "jason";
  home.homeDirectory = "/home/jason";
  home.stateVersion = "23.11";

  home.sessionVariables.EDITOR = "vscode";

  imports = [
    ./modules/firefox.nix
    ./modules/fish.nix
    ./modules/git.nix
    ./modules/vscode.nix
  ];

  home.file = let
    autostartPrograms =
      [ pkgs-unstable.brave pkgs-unstable.obsidian pkgs-unstable.vscode ];

    envFile = builtins.readFile "/home/jason/home-nix/.env";
    envLines = builtins.filter (line: line != "" && line != [ ])
      (builtins.split "\n" envFile);
    env = builtins.listToAttrs (map (line:
      let
        parts = builtins.split "=" line;
        key = builtins.elemAt parts 0;
        value = builtins.elemAt parts 2;
      in {
        name = key;
        value = value;
      }) envLines);

  in builtins.listToAttrs ([{
    name = ".config/nix/netrc";
    value = {
      text = "machine freckle-private.cachix.org password ${env.TOKEN}";
    };
  }] ++ [{
    name = ".stack/config.yaml";
    value = {
      text = ''
        nix: { enable: false }
        system-ghc: true
        recommend-stack-upgrade: false
        ghc-options:
          "$everything": -fconstraint-solver-iterations=10 -O0 -fobject-code -j +RTS -A64m -n2m -RTS
      '';
    };
  }] ++ (map (pkg: {
    name = ".config/autostart/" + pkg.pname + ".desktop";
    value = if pkg ? desktopItem then {
      text = pkg.desktopItem.text;
    } else {
      source = if pkg.pname == "brave" then
        (pkg + "/share/applications/brave-browser.desktop")
      else
        (pkg + "/share/applications/" + pkg.pname + ".desktop");
    };
  }) autostartPrograms));
}

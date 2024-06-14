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
      [ pkgs.alacritty pkgs-unstable.obsidian pkgs-unstable.vscode ];
    # pkgs-unstable.brave
    # removed brave because it doesn't use dark mode when autostarted

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
    name = ".config/helix/config.toml";
    value = { text = ''theme = "onedark"''; };
  }] ++ [{
    name = ".config/nix/netrc";
    value = {
      text = "machine freckle-private.cachix.org password ${env.TOKEN}";
    };
  }] ++ [{
    name = ".aws/config";
    value = {
      text = ''
        [profile freckle]
        sso_start_url = https://d-90675613ab.awsapps.com/start
        sso_region = us-east-1
        sso_account_id = 853032795538
        sso_role_name = Freckle-Prod-Engineers
        region = us-east-1

        [profile freckle-dev]
        sso_start_url = https://d-90675613ab.awsapps.com/start
        sso_region = us-east-1
        sso_account_id = 539282909833
        sso_role_name = Freckle-Dev-Engineers
        region = us-east-1
      '';
    };
  }] ++ [{
    name = ".stack/config.yaml";
    value = {
      text = ''
        nix: { enable: false }
        system-ghc: true
        recommend-stack-upgrade: false
        notify-if-nix-on-path: false
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

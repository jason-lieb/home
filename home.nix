{ config, pkgs, pkgs-unstable, ... }:

{
  home.username = "jason";
  home.homeDirectory = "/home/jason";
  home.stateVersion = "23.11";

  home.sessionVariables.EDITOR = "vscode";

  imports = [ ./modules/git.nix ./modules/vscode.nix ./modules/fish.nix ];

  home.file = let
    autostartPrograms =
      [ pkgs.brave pkgs-unstable.obsidian pkgs-unstable.vscode ];
  in builtins.listToAttrs (map (pkg: {
    name = ".config/autostart/" + pkg.pname + ".desktop";
    value = if pkg ? desktopItem then {
      text = pkg.desktopItem.text;
    } else {
      source = (pkg + "/share/applications/" + pkg.pname + ".desktop");
    };
  }) autostartPrograms);
}

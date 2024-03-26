{ config, pkgs, ... }:

{
  home.username = "jason";
  home.homeDirectory = "/home/jason";
  home.stateVersion = "23.11";

  home.sessionVariables = {
    EDITOR = "vscode";
  };

  imports = [
    ./modules/git.nix
    ./modules/vscode.nix
    ./modules/fish.nix
  ];
}

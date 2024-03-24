{ config, pkgs, ... }:

{
  home.username = "jason";
  home.homeDirectory = "/home/jason";
  home.stateVersion = "23.11";

  home.sessionVariables = {
    EDITOR = "vscode";
    SHELL = "${pkgs.fish}/bin/fish";
  };

  imports = [
    ./git.nix
    ./vscode.nix
    ./fish.nix
  ]
}

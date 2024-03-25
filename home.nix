{ config, pkgs, ... }:

{
  home.username = "jason";
  home.homeDirectory = "/home/jason";
  home.stateVersion = "23.11";

  # Might need to add
  #programs.home-manager.enable = true;
  #nixpkgs.config.allowUnfree = true;

  home.sessionVariables = {
    EDITOR = "vscode";
    SHELL = "${pkgs.fish}/bin/fish";
  };

  imports = [
    ./modules/git.nix
    ./modules/vscode.nix
    ./modules/fish.nix
  ];

  programs.zoxide = {
    enable = true;
  };
}

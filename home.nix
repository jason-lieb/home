{ config, pkgs, ... }:

{ 
  home.username = "jason";
  home.homeDirectory = "/home/jason";
  home.stateVersion = "23.11";

  programs.neovim.enable = true;
  programs.git = {
    enable = true;
  
    userName = "Jason Lieb";
    userEmail = "Jason.lieb@outlook.com";
  };

  # home.packages = with pkgs; [
  # ];

  home.sessionVariables = {
    EDITOR = "nvim";
    SHELL = "${pkgs.fish}/bin/fish";
  };

  programs.fish = {
    enable = true;

    shellAliases = {
      c = "clear";
    };
  };
}

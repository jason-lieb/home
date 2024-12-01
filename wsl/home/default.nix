{ pkgs, ... }:

{
  home = {
    username = "nixos";
    homeDirectory = "/home/nixos";
    stateVersion = "24.05";
  };

  home.sessionVariables.EDITOR = "code";

  #programs.direnv = {
  #  enable = true;
  #  nix-direnv.enable = true;
  #};

  imports = [
    ./fish.nix
    ./git.nix
    # ./vscode.nix
  ];

  #home.packages = (
  #  with pkgs;
  #  [
      # bat
      # gh
      # htop
      # just
      # jq
      # gnumake
      # gparted
      # lf
      # lsof
      # neofetch
      # nixfmt-rfc-style
      # ripgrep
      # wget
      # zoxide
   # ]
  #);

  #home.file =
  #  let
  #    env = import ./env.nix;
  #    nix-cache = import ./nix-cache.nix { inherit env; };
  #  in
  #  builtins.listToAttrs ([ nix-cache ]);
}

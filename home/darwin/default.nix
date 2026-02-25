{ pkgs, ... }:
{
  imports = [ ../shared ];

  home.packages = with pkgs; [
    docker
    colima
  ];
}

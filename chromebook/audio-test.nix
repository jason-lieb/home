let
  pkgs = import <nixpkgs> { };
in
import ./audio.nix { inherit pkgs; }

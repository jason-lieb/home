{ inputs, ... }:

{
  nix.gc = {
    automatic = true;
    dates = "06:00";
    options = "--delete-older-than 10d";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "06:05" ];
  };

  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "06:10";
    # randomizedDelaySec = "30min";
  };
}

{ home-manager }:
{
  home.file =
    if home-manager then
      {
        ".config/nix/nix.conf".text = ''
          experimental-features = nix-command flakes
          auto-optimise-store = true
          netrc-file = /home/jason/.config/nix/netrc
        '';
      }
    else
      { };
}

{ home-manager }:
{
  home.file.".config/nix/nix.conf".text =
    if home-manager then
      ''
        experimental-features = nix-command flakes
        auto-optimise-store = true
        netrc-file = /home/jason/.config/nix/netrc
      ''
    else
      "";
}

{
  name = ".config/nix/nix.conf";
  value.text = ''
    experimental-features = nix-command flakes
    auto-optimise-store = true
    max-jobs = 8
    build-cores = 0
    netrc-file = /home/jason/.config/nix/netrc
  '';
}

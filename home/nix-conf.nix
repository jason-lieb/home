{
  name = ".config/nix/nix.conf";
  value.text = ''
    experimental-features = nix-command flakes
    auto-optimise-store = true
    netrc-file = /home/jason/.config/nix/netrc

    trusted-users = @wheel
    max-jobs = 8
    build-cores = 0
    substituters = "https://freckle.cachix.org" "https://freckle-private.cachix.org" "https://yazi.cachix.org" "https://cosmic.cachix.org/"
    trusted-public-keys = "freckle.cachix.org-1:WnI1pZdwLf2vnP9Fx7OGbVSREqqi4HM2OhNjYmZ7odo=" "freckle-private.cachix.org-1:zbTfpeeq5YBCPOjheu0gLyVPVeM6K2dc1e8ei8fE0AI=" "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k=" "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dP
  '';
}

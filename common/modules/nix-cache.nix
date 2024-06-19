{ env }:
{
  name = ".config/nix/netrc";
  value = {
    text = "machine freckle-private.cachix.org password ${env.TOKEN}";
  };
}

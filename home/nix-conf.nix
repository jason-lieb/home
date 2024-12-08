{ env }:

{
  name = ".config/nix/nix.conf";
  value.text = "access-tokens = github.com=${env.GITHUB_TOKEN}";
}

{ self, ... }:

{
  users.users.davish = {
    name = "jason.lieb";
    home = "/Users/jason.lieb";
  };

  services.nix-daemon.enable = true;

  system.configurationRevision = self.rev or self.dirtyRev or null;

  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";
}

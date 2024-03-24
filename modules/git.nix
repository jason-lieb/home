{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    userName = "Jason Lieb";
    userEmail = "Jason.lieb@outlook.com";

    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      core = {
        editor = "code --wait";
      };
      fetch = {
        prune = true;
      };
      merge = {
        ff = only;
      };
      pull = {
        ff = only;
      };
      push = {
        default = current;
      };

      # [rebase]
      # 	autoSquash = true
      # 	autoStash = true
      # 	stat = true
    }
  };
}

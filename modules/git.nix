{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;

    userName = "Jason Lieb";
    userEmail = "Jason.lieb@outlook.com";

    extraConfig = {
      init.defaultBranch = "main";
      core.editor = "code --wait";
      fetch.prune = true;
      merge.ff = "only";
      #merge.tool = "nvimdiff";
      pull.ff = "only";
      pull.autostash = true;
      push.default = "current";
      rebase.autoSquash = true;
      rebase.autoStash = true;
      rebase.stat = true;
      rerere.enabled = true;
    };
  };
}

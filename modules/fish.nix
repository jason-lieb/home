{ config, pkgs, ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      c = "clear";
      cd = "z";
      g = "git";
      gac = "git add -A; git commit -m";
      la = "ls -A";
      ll = "ls -l";
      lr = "ls -R"; # recursive ls
      m = "make";
      mon-desk = "~/home/utils/switch-to-desk-monitors.sh";
      mon-tv = "~/home/utils/switch-to-tv-monitor.sh";
      main = "git checkout main";
      pull = "git pull origin";
      push = "git push origin";
      fpush = "git push origin --force";
      "run-qa" = "git commit --allow-empty -m '[qa]'";
      "run-cy" = "git commit --allow-empty -m '[cy]'";
      up = "make update";
      bran = "git branch | tr '\\n' '\\n'";
      dbran = "git branch -D";
      nbran = "git checkout -b";
      sbran = "git checkout";
      "cd.." = "cd ..";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      suod = "sudo";
      "enter-db" = "docker exec -it freckle-megarepo-postgres bash -c \"psql -U postgres -d classroom_dev\"";
      "format-backend-whole" = "stack exec -- fourmolu -i .";
      "format-backend" = "git diff --name-only HEAD \"*.hs\" | xargs fourmolu -i";
      rebase = "git fetch origin main && git rebase origin/main";
      squash = "git rebase -i origin/main";
      nb = "npm run build";
      gcp = "git cherry-pick";
      nr = "sudo nixos-rebuild switch --flake /home/jason/home-nix";
      hms = "home-manager switch";
    };
  };
}

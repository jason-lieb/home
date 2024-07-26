{ pkgs }:

let
  autostartPrograms = [
    pkgs.obsidian
    pkgs.vscode
  ];
in
map (pkg: {
  name = ".config/autostart/" + pkg.pname + ".desktop";
  value =
    if pkg ? desktopItem then
      { text = pkg.desktopItem.text; }
    else
      {
        source =
          if pkg.pname == "brave" then
            (pkg + "/share/applications/brave-browser.desktop")
          else if pkg.pname == "alacritty" then
            (pkg + "/share/applications/Alacritty.desktop")
          else
            (pkg + "/share/applications/" + pkg.pname + ".desktop");
      };
}) autostartPrograms

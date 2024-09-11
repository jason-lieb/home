{ pkgs }:
[
  {
    name = ".local/share/applications/Alacritty.desktop";
    value.source = "${pkgs.alacritty}/share/applications/Alacritty.desktop";
  }
  {
    name = ".local/share/applications/brave-browser.desktop";
    value.source = "${pkgs.brave}/share/applications/brave-browser.desktop";
  }
  {
    name = ".local/share/applications/obsidian.desktop";
    value.source = "${pkgs.obsidian}/share/applications/obsidian.desktop";
  }
  {
    name = ".local/share/applications/vscode.desktop";
    value.source = "${pkgs.vscode}/share/applications/vscode.desktop";
  }
]

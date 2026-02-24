{
  pkgs,
  pkgs-unstable,
  hostname,
  ...
}:
let
  isMini = hostname == "mini";
in
{
  imports = [
    ../shared
    ./plasma.nix
  ];

  services.flatpak = {
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      "io.github.am2r_community_developers.AM2RLauncher"
    ];
    overrides."io.github.am2r_community_developers.AM2RLauncher".Context.filesystems = [
      "/run/udev:ro"
    ];
  };

  home.packages = with pkgs; [
    eyedropper
    gparted
    wl-clipboard
    brave
    firefox
    google-chrome
    vivaldi
    github-desktop
    mgba
    obsidian
  ];

  xdg.mimeApps =
    let
      defaultBrowser = if isMini then "brave-browser.desktop" else "vivaldi-stable.desktop";
    in
    {
      enable = true;
      defaultApplications = {
        "application/zip" = "org.kde.dolphin.desktop";
        "application/pdf" = "org.kde.okular.desktop";
        "text/html" = defaultBrowser;
        "video/mp4" = defaultBrowser;
        "x-scheme-handler/http" = defaultBrowser;
        "x-scheme-handler/https" = defaultBrowser;
        "image/jpeg" = "org.kde.gwenview.desktop";
        "image/png" = "org.kde.gwenview.desktop";
      };
    };

  xdg.configFile =
    if isMini then
      {
        "autostart/brave-browser.desktop".source = "${pkgs.brave}/share/applications/brave-browser.desktop";
      }
    else
      {
        "autostart/vivaldi-stable.desktop".source =
          "${pkgs.vivaldi}/share/applications/vivaldi-stable.desktop";
        "autostart/obsidian.desktop".source = "${pkgs.obsidian}/share/applications/obsidian.desktop";
        "autostart/cursor.desktop".source =
          "${pkgs-unstable.code-cursor}/share/applications/cursor.desktop";
      };

  home.activation.syncCursorSettings = ''
    mkdir -p ~/.config/Cursor/User

    if [ -f ~/.config/Code/User/settings.json ] && [ ! -e ~/.config/Cursor/User/settings.json ]; then
      ln -sf ~/.config/Code/User/settings.json ~/.config/Cursor/User/settings.json
    fi

    if [ -f ~/.config/Code/User/keybindings.json ] && [ ! -e ~/.config/Cursor/User/keybindings.json ]; then
      ln -sf ~/.config/Code/User/keybindings.json ~/.config/Cursor/User/keybindings.json
    fi
  '';
}

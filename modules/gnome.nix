{ config, pkgs, ... }:

{
  services.xserver.displayManager.gdm.enable = true;

  environment.systemPackages = with pkgs; [
    gnome.gnome-tweaks
    gnome-extension-manager
    gnomeExtensions.caffeine
    gnomeExtensions.display-ddc-brightness-volume
  ];

  environment.gnome.excludePackages = with pkgs.gnome; [
    baobab
    cheese
    eog
    epiphany
    gedit
    simple-scan
    totem
    yelp
    evince
    file-roller
    geary
    seahorse

    gnome-calendar
    gnome-characters
    gnome-clocks
    gnome-contacts
    gnome-font-viewer
    gnome-logs
    gnome-maps
    gnome-music
    gnome-screenshot
    gnome-weather
  ];


  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  # systemd.services."getty@tty1".enable = false;
  # systemd.services."autovt@tty1".enable = false;

  services.xserver.desktopManager.gnome = {
    enable = true;
    # extensions = with pkgs; [
    #   gnomeExtensions.caffeine
    #   gnomeExtensions.display-ddc-brightness-volume
    #   gnomeExtensions.launch-new-instance
    # ];
    extraGSettingsOverrides = ''
      [org.gnome.desktop.wm.keybindings]
      switch-windows=['<Alt>Tab']

      [org/gnome/desktop/interface]
      clock-format='12h'
      color-scheme='prefer-dark'

      [org/gnome/desktop/notifications]
      application-children=['gnome-power-panel', 'org-gnome-software', 'org-gnome-nautilus', 'gnome-network-panel', 'org-gnome-extensions-desktop', 'brave-browser', 'org-gnome-texteditor', 'code', 'org-gnome-evince']

      [org/gnome/desktop/notifications/application/gnome-power-panel]
      application-id='gnome-power-panel.desktop'
      enable=false

      [org/gnome/desktop/peripherals/keyboard]
      numlock-state=true

      [org/gnome/desktop/screensaver]
      lock-enabled=false

      [org/gnome/desktop/wm/preferences]
      auto-raise=false
      button-layout='appmenu:minimize,maximize,close'
      focus-mode='click'
      num-workspaces=5

      [org/gnome/mutter]
      center-new-windows=true
      dynamic-workspaces=false
      workspaces-only-on-primary=true

      [org/gnome/settings-daemon/plugins/color]
      night-light-enabled=true
      night-light-temperature=uint32 3700

      [org/gnome/settings-daemon/plugins/power]
      sleep-inactive-ac-timeout=3600
      sleep-inactive-ac-type='suspend'

      [org/gnome/shell]
      app-picker-layout=[{'org.gnome.Contacts.desktop': <{'position': <0>}>, 'org.gnome.Weather.desktop': <{'position': <1>}>, 'org.gnome.clocks.desktop': <{'position': <2>}>, 'org.gnome.Maps.desktop': <{'position': <3>}>, 'chromium-browser.desktop': <{'position': <4>}>, 'org.gnome.Totem.desktop': <{'position': <5>}>, 'org.gnome.Calculator.desktop': <{'position': <6>}>, 'org.gnome.Extensions.desktop': <{'position': <7>}>, 'simple-scan.desktop': <{'position': <8>}>, 'org.gnome.Settings.desktop': <{'position': <9>}>, 'gnome-system-monitor.desktop': <{'position': <10>}>, 'org.gnome.Boxes.desktop': <{'position': <11>}>, 'org.gnome.Terminal.desktop': <{'position': <12>}>, 'Utilities': <{'position': <13>}>, 'fish.desktop': <{'position': <14>}>, 'yelp.desktop': <{'position': <15>}>, 'htop.desktop': <{'position': <16>}>, 'org.gnome.Cheese.desktop': <{'position': <17>}>, 'nvim.desktop': <{'position': <18>}>, 'org.gnome.TextEditor.desktop': <{'position': <19>}>, 'timeshift-gtk.desktop': <{'position': <20>}>, 'org.gnome.Tour.desktop': <{'position': <21>}>}, {'org.gnome.Calendar.desktop': <{'position': <0>}>, 'io.github.thetumultuousunicornofdarkness.cpu-x.desktop': <{'position': <1>}>, 'firefox.desktop': <{'position': <2>}>, 'com.valvesoftware.Steam.desktop': <{'position': <3>}>, 'brave-cmkncekebbebpfilplodngbpllndjkfo-Default.desktop': <{'position': <4>}>, 'dosbox-staging.desktop': <{'position': <5>}>, 'wine-notepad.desktop': <{'position': <6>}>, 'virtualbox.desktop': <{'position': <7>}>, 'wine-Programs-RaceHub-RaceHub™.desktop': <{'position': <8>}>, 'wine-regedit.desktop': <{'position': <9>}>, 'dev.lizardbyte.app.Sunshine.desktop': <{'position': <10>}>, 'wine-wineboot.desktop': <{'position': <11>}>, 'wine-winecfg.desktop': <{'position': <12>}>, 'wine-winefile.desktop': <{'position': <13>}>, 'wine-winhelp.desktop': <{'position': <14>}>, 'wine-oleview.desktop': <{'position': <15>}>, 'wine-uninstaller.desktop': <{'position': <16>}>, 'wine-wordpad.desktop': <{'position': <17>}>, 'wine-winemine.desktop': <{'position': <18>}>}]
      command-history=['r']
      disable-user-extensions=false
      disabled-extensions=['wsmatrix@martin.zurowietz.de', 'window-list@gnome-shell-extensions.gcampax.github.com', 'space-bar@luchrioh']
      enabled-extensions=['launch-new-instance@gnome-shell-extensions.gcampax.github.com', 'caffeine@patapon.info', 'display-brightness-ddcutil@themightydeity.github.com', 'wsmatrix@martin.zurowietz.de']
      favorite-apps=['org.gnome.Nautilus.desktop', 'brave-browser.desktop', 'Alacritty.desktop', 'code.desktop', 'org.gnome.Software.desktop']
      last-selected-power-profile='performance'
      welcome-dialog-last-shown-version='45.2'

      [org/gnome/shell/app-switcher]
      current-workspace-only=true

      [org/gnome/shell/extensions/caffeine]
      duration-timer=2
      indicator-position-max=4
      screen-blank='always'
      show-notifications=false

      [org/gnome/shell/extensions/display-brightness-ddcutil]
      ddcutil-binary-path='/usr/bin/ddcutil'
      ddcutil-queue-ms=130.0
      ddcutil-sleep-multiplier=40.0
      decrease-brightness-shortcut=['<Control>XF86MonBrightnessDown']
      increase-brightness-shortcut=['<Control>XF86MonBrightnessUp']
      only-all-slider=true
      position-system-menu=3.0
      show-all-slider=true
      step-change-keyboard=2.0

      [org/gnome/tweaks]
      show-extensions-notice=false

      [org/gtk/gtk4/settings/file-chooser]
      date-format='regular'
      location-mode='path-bar'
      show-hidden=true
      show-size-column=true
      show-type-column=true
      sidebar-width=140
      sort-column='name'
      sort-directories-first=false
      sort-order='ascending'
      type-format='category'
      view-type='list'
      window-size=(1571, 888)

      [org/gtk/settings/file-chooser]
      clock-format='12h'
      date-format='regular'
      location-mode='path-bar'
      show-hidden=false
      show-size-column=true
      show-type-column=true
      sidebar-width=157
      sort-column='name'
      sort-directories-first=false
      sort-order='ascending'
      type-format='category'
      window-position=(0, 775)
      window-size=(1203, 902)
    '';
  };
}

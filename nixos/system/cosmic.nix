{ ... }:

{
  services = {
    desktopManager.cosmic.enable = true;
    displayManager.cosmic-greeter.enable = true;
  };

  hardware.system76.enableAll = true;
}

{ config, pkgs, ... }:

{
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma6.enable = true;

  services.displayManager.defaultSession = "plasma";

  environment.systemPackages = with pkgs; [ kdePackages.colord-kde ];
}

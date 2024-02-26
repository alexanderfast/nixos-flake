{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../configuration.nix
    ../../modules/i3.nix
  ];

  services.xserver.xkb.options = "ctrl:swapcaps";
  networking.hostName = "laptop";
  networking.networkmanager.wifi.powersave = false;

  environment.systemPackages = with pkgs; [
    brightnessctl
  ];

}

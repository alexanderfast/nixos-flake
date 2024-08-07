{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../configuration.nix
    ../../modules/home-xfce4-i3.nix
    ../../modules/bootgrub.nix
  ];

  services.xserver.xkb.options = "ctrl:swapcaps";
  services.libinput.enable = true;
  services.libinput.touchpad.disableWhileTyping = true;
  services.xserver.synaptics.enable = false;
  networking.hostName = "laptop";
  networking.networkmanager.wifi.powersave = false;

  environment.systemPackages = with pkgs; [ brightnessctl ];
}

{ config, pkgs, ... }:

{
  imports =
    [ ./hardware.nix ../../configuration.nix ../../modules/home-xfce4-i3.nix ];

  services.xserver.xkb.options = "ctrl:swapcaps";
  services.xserver.libinput.touchpad.disableWhileTyping = true;
  networking.hostName = "laptop";
  networking.networkmanager.wifi.powersave = false;

  environment.systemPackages = with pkgs; [ brightnessctl ];
}

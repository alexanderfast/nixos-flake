{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware.nix
    ../../configuration.nix
  ];

  services.xserver.xkb.options = "ctrl:swapcaps";
  networking.hostName = "laptop";
  networking.networkmanager.wifi.powersave = false;
}

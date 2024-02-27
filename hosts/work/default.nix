{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware.nix
    ../../configuration.nix
    ../../home-xfce4-i3.nix
    #../../modules/i3.nix
    ../../modules/nvidia.nix
  ];

  networking.hostName = "work";
}

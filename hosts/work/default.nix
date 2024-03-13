{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware.nix
    ../../configuration.nix
    ../../modules/home-xfce4-i3.nix
    ../../modules/nvidia.nix
    ../../modules/bootgrub.nix
  ];

  networking.hostName = "work";
}

{ config, pkgs, ... }:

{
  imports = [ # Include the results of the hardware scan.
    ./hardware.nix
    ../../configuration.nix
    ../modules/nvidia.nix
  ];

  networking.hostName = "work";
}

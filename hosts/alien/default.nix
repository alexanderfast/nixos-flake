{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../configuration.nix
    ../../modules/plasma.nix
    #../../modules/nvidia.nix
  ];

  networking.hostName = "alien";
}

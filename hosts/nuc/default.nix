{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../configuration.nix
    #../../xfc4.nix
    ../../modules/plasma.nix
    #../../modules/nvidia.nix
    ../../modules/bootsystemd.nix
  ];

  networking.hostName = "nuc";
}

{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../configuration.nix
    ../../xfc4.nix
    ../../modules/bootgrub.nix
    ../../modules/plasma.nix
    #../../modules/nvidia.nix
  ];

  networking.hostName = "alien";
}

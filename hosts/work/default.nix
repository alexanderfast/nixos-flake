{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../modules/configuration.nix
    ../../modules/home-xfce4-i3.nix
    ../../modules/nvidia.nix
    ../../modules/bootgrub.nix
  ];

  networking.hostName = "work";

  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      cmake
    ];
  };

  virtualisation.virtualbox.host.enable = true;
  users.extraGroups.vboxusers.members = [ "users" ];
}

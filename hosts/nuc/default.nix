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

  environment.systemPackages =
    [ pkgs.jellyfin pkgs.jellyfin-web pkgs.jellyfin-ffmpeg ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  #services.qbittorrent = {
  #  enable = true;
  #  dataDir = "/var/lib/qbittorrent";
  #  openFirewall = true;
  #  port = 8080;
  #};
}

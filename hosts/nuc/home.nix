{ config, pkgs, ... }:

{
  imports = [ ../../home-base.nix ../../home-desktop.nix  ];

  #home.packages = [
  #  qbittorrent
  #];

  home.packages = with pkgs; [
    qbittorrent
  ];

}

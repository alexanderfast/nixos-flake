{ config, pkgs, ... }:

{
  imports = [
    ./home-base.nix
  ];

  home.packages = [
    pkgs.firefox
    pkgs.slack
    pkgs.rofi
    pkgs.feh
    pkgs.dunst
    pkgs.libnotify
  ];

}

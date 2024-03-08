{ config, pkgs, ... }:

{
  imports = [ ./home-base.nix ];

  home.packages = with pkgs; [
    firefox
    slack
    rofi
    feh
    dunst
    libnotify
    vlc
    arandr
    scrot
    imagemagick
  ];
}

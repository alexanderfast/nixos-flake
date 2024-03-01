{ config, pkgs, ... }:

{
  imports = [ ../../home-base.nix ../../home-desktop.nix ];

  home.packages = [
    pkgs.hello

    pkgs.xfce.xfce4-power-manager
    pkgs.xfce.xfce4-battery-plugin
  ];

}

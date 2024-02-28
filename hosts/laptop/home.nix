{ config, pkgs, ... }:

{
  imports = [
    ../../home-base.nix
  ];

  home.packages = [
    pkgs.hello
  ];

}

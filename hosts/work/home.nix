{ config, pkgs, ... }:

{
  imports = [ ../../home-base.nix ../../home-desktop.nix ];

  home.packages = [
    pkgs.hello

    pkgs.k9s
    pkgs.kubernetes
    pkgs.vault
    pkgs.go-task
    pkgs.jq
    pkgs.tree
  ];
}

{ config, pkgs, ... }:

{
  #imports = [ ../../home-base.nix ../../home-desktop.nix ];

  home.packages = with pkgs; [
    #k9s
    #kubernetes
    #vault
    #go-task
    #jq
    #ninja
    btop
  ];
}

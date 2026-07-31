# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  config,
  pkgs,
  ...
}:

{
  imports = [
    ./base.nix
  ];

  home.packages = with pkgs; [
    stepmania
    claude-code
  ];
}

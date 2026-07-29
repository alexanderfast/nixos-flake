# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  config,
  pkgs,
  ...
}:

{
  # You can import other home-manager modules here
  imports = [
    ./base.nix
    ./home.nix
  ];

  home.packages = with pkgs; [
    stepmania
  ];
}

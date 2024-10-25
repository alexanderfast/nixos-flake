# README

My Nix OS flake.

### Cheat sheet

Common commands

```
nix flake lock --update-input nixpkgs --update-input nix --update-input home-manager
sudo nixos-rebuild switch --flake '.#work'
home-manager switch --flake '#alex@work'
```

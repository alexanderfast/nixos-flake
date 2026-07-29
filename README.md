# README

My Nix OS flake.

### Cheat sheet

Common commands

```
nix flake update nixpkgs home-manager
sudo nixos-rebuild switch --flake '.#nuc'
```

home-manager is wired in as a NixOS module (see `home-manager.users.alex`
in `flake.nix`), so there is no separate `home-manager switch` step and no
`homeConfigurations` output -- `nixos-rebuild switch` applies both.

To check a change without activating it:

```
nix flake check
nixos-rebuild build --flake '.#nuc'   # builds ./result, activates nothing
```

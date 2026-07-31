# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # TEMPORARY BRIDGE -- see the nixpkgs-claude input in flake.nix for why.
  # Takes claude-code (and only claude-code) from a newer revision of the same
  # stable 25.11 branch, so the rest of the system stays on its current pin.
  #
  # This is `claude-code`, the buildNpmPackage build that runs on nodejs -- NOT
  # `claude-code-bin`, which fetches a prebuilt binary and runs autoPatchelfHook
  # over it. No patchelf is involved anywhere in this path.
  #
  # Note `import` rather than `.legacyPackages.<system>`: legacyPackages does not
  # inherit this flake's `nixpkgs.config`, and claude-code is unfree, so that
  # form fails with a licence assertion.
  #
  # GOAL: delete this overlay once the main nixpkgs is new enough to supply
  # claude-code directly.
  recent-claude = final: prev: {
    claude-code =
      (import inputs.nixpkgs-claude {
        system = prev.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      }).claude-code;
  };
}

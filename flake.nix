{
  description = "NixOS and home-manager configuration for alex's nuc";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    # nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # TEMPORARY BRIDGE -- a second nixpkgs, tracking the same stable 25.11
    # branch, used for exactly one package: claude-code.
    #
    # Why: the main `nixpkgs` above is pinned to 2026-04-17, which carries
    # claude-code 2.1.81 -- too old for Remote Control. Updating the main input
    # would drag ~450 derivations along with it, including the kernel
    # (6.12.81 -> 6.12.93, needing a reboot) and dnsmasq (2.91 -> 2.92rel2,
    # which serves the whole house). This input moves claude-code alone.
    #
    # Update claude-code, and nothing else, with:
    #     nix flake update nixpkgs-claude
    #
    # GOAL: delete this input. Once the main nixpkgs is updated, take
    # claude-code from it and drop both this input and the recent-claude
    # overlay in overlays/default.nix. Tracked on the NUC Trello board.
    nixpkgs-claude.url = "github:nixos/nixpkgs/nixos-25.11";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NOTE: there is deliberately no nix-ld input. `programs.nix-ld.enable` in
    # modules/configuration.nix is the nixpkgs module, not this flake -- the
    # input was pulled in and never referenced.

    # gitlablistpy = {
    #   url = "github:alexanderfast/gitlablistpy";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
    #
    # nix-minecraft = {
    #   url = "github:Infinidoge/nix-minecraft";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    # All hosts here are x86_64-linux; add more when that changes.
    systems = [
      "x86_64-linux"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    #
    # `nuc` is the only live host. The work, laptop and alien configurations
    # were removed on 2026-07-31 -- recover them from git history if a machine
    # comes back, but expect to port them: they were last evaluated against
    # nixpkgs 24.11-era options, and one of them (alien) already referenced
    # files that no longer exist.
    nixosConfigurations = {
      nuc = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          # > Our main nixos configuration file <
          ./nixos/nuc.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.alex = ./home-manager/nuc.nix;
          }
        ];
      };
    };

    # devShells.x86_64-linux.default =
    #   packages.mkShell { packages = with packages; [ nixfmt ]; };
  };
}

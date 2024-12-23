{
  description = "A very basic flake";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    # nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    # nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-ld = {
      url = "github:Mic92/nix-ld";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gitlablistpy = {
      url = "github:alexanderfast/gitlablistpy";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, nix-ld, gitlablistpy, ... }@inputs: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "aarch64-linux"
      "i686-linux"
      "x86_64-linux"
      "aarch64-darwin"
      "x86_64-darwin"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
    # pkgs = import nixpkgs {
    #   inherit system;
    #   config.allowUnfree = true;
    # };
    # lib = nixpkgs.lib;
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};
    # Reusable nixos modules you might want to export
    # These are usually stuff you would upstream into nixpkgs
    nixosModules = import ./modules/nixos;
    # Reusable home-manager modules you might want to export
    # These are usually stuff you would upstream into home-manager
    homeManagerModules = import ./modules/home-manager;

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      work = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          # > Our main nixos configuration file <
          ./nixos/configuration.nix
        ];
      };
    };

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      nuc = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          # > Our main nixos configuration file <
          ./nixos/nuc.nix
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      "alex@work" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          # > Our main home-manager configuration file <
          ./home-manager/home.nix
        ];
      };
    };

    # # NixOS configuration entrypoint
    # # Available through 'nixos-rebuild --flake .#your-hostname'
    # nixosConfigurations = {
    #   work = nixpkgs.lib.nixosSystem {
    #     inherit system;
    #     modules = [
    #       ./hosts/work
    #       home-manager.nixosModules.home-manager
    #       {
    #         home-manager.useGlobalPkgs = true;
    #         home-manager.useUserPackages = true;
    #         home-manager.users.alex = {
    #           imports = [ ./hosts/work/home.nix ];
    #         };
    #       }
    #       nix-ld.nixosModules.nix-ld
    #       {
    #         programs.nix-ld.enable = true;
    #         programs.nix-ld.libraries = with pkgs; [ stdenv.cc.cc libz ];
    #       }
    #       {
    #         # # TODO: move to home manager
    #         # environment.systemPackages =
    #         #   [ gitlablistpy.packages.${system}.default ];
    #       }
    #     ];
    #   };
    #
    # homeManagerConfigurations = {
    #   alex = home-manager.lib.homeManagerConfiguration {
    #     #inherit system pkgs;
    #     pkgs = nixpkgs.legacyPackages.${system};
    #     modules = [ ./home-base.nix ];
    #   };
    # };

  #   devShells.x86_64-linux.default =
  #     packages.mkShell { packages = with packages; [ nixfmt ]; };
  };
}

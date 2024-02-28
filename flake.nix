{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      lib = nixpkgs.lib;
    in {
      nixosConfigurations = {
        alien = lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/alien
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.alex = { imports = [ ./home/alien/home.nix ]; };
            }
          ];
        };

        laptop = lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/laptop
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.alex = { imports = [ ./hosts/laptop/home.nix ]; };
            }
          ];
        };

        work = lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/work
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.alex = { imports = [ ./home/work/home.nix ]; };
            }
          ];
        };
      };

      homeManagerConfigurations = {
        alex = home-manager.lib.homeManagerConfiguration {
          #inherit system pkgs;
          pkgs = nixpkgs.legacyPackages.${system};
          modules = [ ./home-base.nix ];
        };
      };
    };
}

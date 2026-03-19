{
  description = "NixOS configuration for zenbook - desktop + homelab hybrid";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.zenbook = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          # Host-specific config (hardware, boot, networking, users)
          ./hosts/zenbook

          # Role modules - add/remove as needed
          # ./modules/desktop.nix
          ./modules/development.nix
          ./modules/hypervisor.nix

          # Home Manager as NixOS module (single nixos-rebuild updates everything)
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.steven = import ./home/steven.nix;
          }
        ];
      };
    };
}

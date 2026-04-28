{
  description = "NixOS configuration for zenbook - desktop + homelab hybrid";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    microvm = {
      url = "github:microvm-nix/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, microvm, sops-nix, nixos-vscode-server, ... }:
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
          ./modules/secrets.nix
          ./modules/k3s-cluster.nix
          ./modules/k3s-backup.nix
          ./modules/wireguard.nix
          microvm.nixosModules.host
          sops-nix.nixosModules.sops

          # Home Manager as NixOS module (single nixos-rebuild updates everything)
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.sharedModules = [
              nixos-vscode-server.homeModules.default
            ];
            home-manager.users.steven = import ./home/steven.nix;
          }
        ];
      };
    };
}

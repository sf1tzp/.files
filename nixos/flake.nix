{
  description = "NixOS configurations for homelab hosts (zenbook + k3s VMs)";

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
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, microvm, sops-nix, nixos-vscode-server, nixos-generators, ... }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";

      # Role modules for the staging-k3s VM, shared between its nixosConfigurations
      # entry (for later `nixos-rebuild --target-host`) and its bootable image.
      stagingK3sModules = [
        ./hosts/staging-k3s/secrets.nix
        ./modules/k3s-server.nix
        ./modules/wireguard.nix
        ./modules/dotfiles.nix  # clone ~/.files from the internal gitea over TLS
                                # (lab CA already trusted via k3s-server.nix)
      ];

      # Home Manager wired in as a NixOS module, so one nixos-rebuild updates the
      # system and steven's dotfiles together. Shared between mkHost (below) and
      # the staging-k3s qcow package build (which doesn't go through mkHost).
      homeManagerModules = [
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

      # Build a NixOS host from the shared base (common.nix) + its host dir +
      # opt-in role modules. Home Manager is included unless home = false
      # (headless infra hosts don't need the dotfiles).
      mkHost = { hostname, extraModules ? [ ], home ? true }:
        lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./modules/common.nix
            ./hosts/${hostname}
            sops-nix.nixosModules.sops
          ] ++ lib.optionals home homeManagerModules ++ extraModules;
        };
    in {
      nixosConfigurations.zenbook = mkHost {
        hostname = "zenbook";
        extraModules = [
          # Role modules - add/remove as needed
          # ./modules/desktop.nix
          ./modules/development.nix
          ./hosts/zenbook/secrets.nix
          ./modules/k3s-cluster.nix
          ./modules/k3s-backup.nix
          ./modules/wireguard.nix
          ./modules/wireguard-lan-gateway.nix
          ./modules/s3-utils.nix
          microvm.nixosModules.host
        ];
      };

      # Single-node k3s VM for Soundship (libvirt). See hosts/staging-k3s.
      # Home Manager is on: steven gets the full dotfiles here, and ~/.files is
      # cloned from the internal gitea at runtime (modules/dotfiles.nix).
      nixosConfigurations.staging-k3s = mkHost {
        hostname = "staging-k3s";
        extraModules = stagingK3sModules;
      };

      # Bootable qcow2 image for the above, built via nixos-generators. Runs on
      # any x86_64 Nix host (e.g. Soundship itself — no NixOS required):
      #   nix build .#staging-k3s-qcow    ->  result/nixos.qcow2
      # Module list mirrors mkHost (common + host dir + sops + Home Manager),
      # plus the qcow format.
      packages.${system}.staging-k3s-qcow = nixos-generators.nixosGenerate {
        inherit system;
        specialArgs = { inherit inputs; };
        format = "qcow";
        modules = [
          ./modules/common.nix
          ./hosts/staging-k3s
          sops-nix.nixosModules.sops
        ] ++ stagingK3sModules ++ homeManagerModules;
      };
    };
}

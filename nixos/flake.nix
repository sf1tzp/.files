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
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Not in nixpkgs; built from its own flake (pinned to a release tag).
    herdr = {
      url = "github:ogulcancelik/herdr/v0.7.5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, microvm, sops-nix, nixos-generators, ... }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";

      # Home Manager wired in as a NixOS module, so one nixos-rebuild updates the
      # system and steven's dotfiles together. Shared between mkHost (below) and
      # the auto-discovered qcow VM builds.
      homeManagerModules = [
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
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

      # qcow VM hosts are self-describing: each hosts/<name>/default.nix imports
      # its own role modules (./secrets.nix, k3s-server, wireguard, dotfiles),
      # so the module set here is uniform — common base + the host dir + sops +
      # Home Manager. That uniformity is what lets the flake auto-discover hosts:
      # a new dir under ./hosts (scaffolded from inventory by create-nixos.yaml)
      # needs no edit here.
      #
      # Physical / bespoke hosts (their own hardware.nix, non-VM module set) are
      # listed here and configured explicitly below instead of auto-discovered.
      physicalHosts = [ "zenbook" ];
      vmHosts = lib.attrNames (lib.filterAttrs
        (name: type: type == "directory" && !(lib.elem name physicalHosts))
        (builtins.readDir ./hosts));

      # Uniform module set for an auto-discovered qcow VM host.
      vmModules = hostname: [
        ./modules/common.nix
        ./hosts/${hostname}
        sops-nix.nixosModules.sops
      ] ++ homeManagerModules;

      # nixosConfigurations entry (for later `nixos-rebuild --target-host`).
      mkVm = hostname: lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = vmModules hostname;
      };

      # Bootable qcow2 image, built via nixos-generators. Runs on any x86_64 Nix
      # host (e.g. Soundship itself — no NixOS required):
      #   nix build .#<hostname>-qcow   ->  result/nixos.qcow2
      # Built by homelab/vms/create-nixos.yaml for each targeted host.
      mkVmQcow = hostname: nixos-generators.nixosGenerate {
        inherit system;
        specialArgs = { inherit inputs; };
        format = "qcow";
        modules = vmModules hostname;
      };
    in {
      nixosConfigurations = {
        zenbook = mkHost {
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
      } // lib.genAttrs vmHosts mkVm;

      # One `<host>-qcow` package per auto-discovered VM host.
      packages.${system} = lib.listToAttrs (map (hostname: {
        name = "${hostname}-qcow";
        value = mkVmQcow hostname;
      }) vmHosts);
    };
}

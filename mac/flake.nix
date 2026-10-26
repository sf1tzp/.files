{
  # The Macs, declared: nix-darwin for the system (packages, zsh, launchd,
  # the Homebrew casks), home-manager for the links into this repo's
  # shell/ tree. One host per darwinConfigurations entry, macmini and
  # macbook-air, over one package list and one cask list.
  #
  #   nix build .#darwinConfigurations.<host>.system
  #   sudo nix-env -p /nix/var/nix/profiles/system --set "$(readlink ./result)"
  #   sudo ./result/sw/bin/darwin-rebuild activate
  #
  # (README.md: why not `switch`, and why the profile step is not optional.)
  #
  # The daemon is Determinate Nix's (nix.enable = false below), so this
  # flake manages nothing about nix itself.
  description = "SFI Macs: nix-darwin + home-manager over the .files shell tree";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # The estates whose meshes a Mac is on (modules/mesh.nix): the repo,
    # not a flake, for its mesh/peers.json. `nix flake update staging`
    # follows a peers.json change; the lock says which peer set is live.
    staging = {
      url = "git+ssh://git@forge.streetfortress.cloud:30022/sfi/staging";
      flake = false;
    };
    estate-hub = {
      url = "git+ssh://git@forge.streetfortress.cloud:30022/sfi/estate-hub";
      flake = false;
    };
    development = {
      url = "git+ssh://git@forge.streetfortress.cloud:30022/sfi/development";
      flake = false;
    };
    production = {
      url = "git+ssh://git@forge.streetfortress.cloud:30022/sfi/production";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs:
    let
      # What every Mac gets: the CLI set, the casks, zsh, the meshes, the
      # lab CA, node_exporter and home-manager over shell/. The host file
      # carries the meshes' addresses, the cleanup mode and its own casks.
      common = [
        ./modules/packages.nix
        ./modules/homebrew.nix
        ./modules/shell.nix
        ./modules/mesh.nix
        ./modules/lab-ca.nix
        ./modules/node-exporter.nix
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # ~/.zshrc and friends are symlinks into this repo already; the
          # first activation moves them aside rather than refusing.
          home-manager.backupFileExtension = "hm-bak";
          home-manager.users.steven = import ./home/steven.nix;
        }
      ];
      mkMac = host: nix-darwin.lib.darwinSystem {
        specialArgs = { inherit inputs; };
        modules = [ host ] ++ common;
      };
    in
    {
      darwinConfigurations.macmini = mkMac ./hosts/macmini.nix;
      darwinConfigurations.macbook-air = mkMac ./hosts/macbook-air.nix;
    };
}

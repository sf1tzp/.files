{
  # The Macs, declared: nix-darwin for the system (packages, zsh, launchd,
  # the Homebrew casks), home-manager for the links into this repo's
  # shell/ tree. One host per darwinConfigurations entry; macmini first,
  # macbook-air when its own Xcode-shaped list is written down.
  #
  #   sudo darwin-rebuild switch --flake ~/.files/mac#macmini
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
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }: {
    darwinConfigurations.macmini = nix-darwin.lib.darwinSystem {
      modules = [
        ./hosts/macmini.nix
        ./modules/packages.nix
        ./modules/shell.nix
        ./modules/homebrew.nix
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
    };
  };
}

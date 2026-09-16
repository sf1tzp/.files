# Host-specific configuration for Zenbook
{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hostname
  networking.hostName = "zenbook";

  # Networking (desktop: NetworkManager manages WiFi)
  networking.networkmanager.enable = true;

  # Desktop/host group memberships, on top of the shared base in common.nix
  users.users.steven.extraGroups = [ "networkmanager" "docker" ];

  # Homelab CA Trust
  # See .files/homelab/k8s/justfile fetch-step-ca-root
  # Copy step-ca-root.pem to .files/nixos/hosts/zenbook/step-ca-root.pem
  security.pki.certificateFiles = [
    ./step-ca-root.pem
  ];

  # Laptop-specific: ignore lid switch when on external power
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  # k3s persistent volume backups
  services.k3s-backup = {
    enable = true;
    passwordFile = config.sops.secrets.restic-password.path;
    includePatterns = [
      "*_gitea_gitea-shared-storage"
      "*_databasus_databasus-storage-databasus-0"
    ];
    s3Targets = [
      # Daily backups, alternated 12h apart so the targets never run together
      {
        name = "rustfs";
        repository = "s3:https://s3.zen.lofi/k3s-backup";
        environmentFile = config.sops.secrets.restic-s3-env-rustfs.path;
        timerConfig = {
          OnCalendar = "*-*-* 07:00:00";
          Persistent = "true";
        };
      }
      {
        name = "offsite";
        repository = "s3:https://us-sea-1.linodeobjects.com/zen-cluster-backups/restic";
        environmentFile = config.sops.secrets.restic-s3-env-offsite.path;
        timerConfig = {
          OnCalendar = "*-*-* 19:00:00";
          Persistent = "true";
        };
      }
      # Backblaze B2 — the fleet's offsite destination (deployments #47).
      # Runs ALONGSIDE the Linode target, not instead of it: the migration
      # is a re-upload rather than a copy (upload to B2 is free, reading
      # 371 GB back out of Linode is not), and the parallel period is
      # itself the validation. The Linode target and its bucket go once B2
      # has a full retention window and a restore has been spot-checked.
      #
      # `sfi-pv-backups/zenbook` follows the fleet convention — bucket by
      # data class, host in the prefix — so the same bucket holds every
      # fort's repo and luxor's central pruner can reap this one too.
      {
        name = "b2";
        repository = "s3:https://s3.us-west-004.backblazeb2.com/sfi-pv-backups/zenbook";
        environmentFile = config.sops.secrets.restic-s3-env-b2.path;
        # NO PRUNING HERE, deliberately. zenbook's B2 credential holds no
        # deleteFiles — the same posture every fort's key has, so a
        # compromised host cannot erase the offsite copy — and `restic
        # forget --prune` removes pack files, so a prune it cannot perform
        # would fail the unit every cycle. Retention for this repo belongs
        # to luxor's `prune` identity, the one delete-capable credential in
        # the fleet (deployments: nixos/modules/pv-prune.nix). The two
        # older targets keep the module's default pruneOpts: their
        # credentials can delete, and nothing central reaps them.
        pruneOpts = [ ];
        # 13:00 keeps the three targets six hours apart (07 / 13 / 19) so
        # they never read the same PVCs at once.
        timerConfig = {
          OnCalendar = "*-*-* 13:00:00";
          Persistent = "true";
        };
      }
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Keep at the fresh install value.
  system.stateVersion = "25.11";
}

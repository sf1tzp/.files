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
    ];
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Keep at the fresh install value.
  system.stateVersion = "25.11";
}

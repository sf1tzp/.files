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

  # Networking
  networking.networkmanager.enable = true;

  # Timezone and locale
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable ZSH system-wide (required for setting it as user's default shell)
  programs.zsh.enable = true;

  # User account
  users.users.steven = {
    isNormalUser = true;
    description = "Steven Fitzpatrick";
    shell = pkgs.zsh;
    extraGroups = [ "networkmanager" "wheel" "docker" "libvirtd" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFSTKL7m9ViSstGGhgg1TBnrWEGkNptCCysU17Oxgfl"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG0sCtYCOvdb/J7yluSSX9yixiG3pvhZo+OtVQWefjVj"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBuuLb9A36fWGYZexMb2soTxpHFB0HVQTHqR8vihvFMD"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINqO0N5rBif1+bFwnluWEmrkaoTAtqTrP/vONG6/fQKl"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBhrjrcm0Mb4gSMGM/GiWXvkZj3a2ej7/MOcw0Qujx+M"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFSfukFhjws+MpZu+qMqgVCoIitc43jGeqEnGMcF4ydQ"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEdgJK6LiKUZ+fQQZX28B1v82hCl1z4RxomJLn5pHiPH"
    ];
  };

  # Nix settings
  nix.settings.allowed-users = [ "steven" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # OpenSSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Firewall
  networking.firewall.allowedTCPPorts = [ 22 ];

  # Laptop-specific: ignore lid switch when on external power
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. Keep at the fresh install value.
  system.stateVersion = "25.11";
}

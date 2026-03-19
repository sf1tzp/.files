# Hypervisor module: libvirt, QEMU/KVM, virt-manager, bridge networking
{ config, pkgs, ... }:

{
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      swtpm.enable = true;                        # TPM emulation (Win11 guests)
      vhostUserPackages = [ pkgs.virtiofsd ];     # virtio filesystem sharing
    };
    allowedBridges = [ "virbr0" "br0" ];
  };

  # USB passthrough support
  virtualisation.spiceUSBRedirection.enable = true;

  # GUI management
  environment.systemPackages = with pkgs; [
    virt-manager
    virt-viewer
  ];

  # Keep NetworkManager away from the bridged ethernet interface
  # (NM continues to manage WiFi for desktop use)
  networking.networkmanager.unmanaged = [ "enp116s0f4u1" ];

  # Bridge networking on wired ethernet
  # VMs get IPs on the same LAN as the host
  networking.bridges.br0 = {
    interfaces = [ "enp116s0f4u1" ];
  };

  networking.interfaces.br0.ipv4.addresses = [{
    address = "10.0.0.6";
    prefixLength = 24;
  }];

  networking.defaultGateway = "10.0.0.1";
  networking.nameservers = [ "10.0.0.2" "8.8.8.8" ];

  # Trust VM bridge traffic through the firewall
  networking.firewall.trustedInterfaces = [ "virbr0" "br0" ];
}

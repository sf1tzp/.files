{ config, lib, pkgs, ... }:

let
  peersData = builtins.fromJSON (builtins.readFile ../../homelab/wireguard/peers.json);
  selfName = "zenbook";
  self = peersData.peers.${selfName};
  otherPeers = lib.filterAttrs (n: _: n != selfName) peersData.peers;
  clients = peersData.clients or {};

  mkMeshPeer = _name: p: {
    publicKey = p.public_key;
    allowedIPs = [ "${p.wg_vpn_ip}/32" ];
    persistentKeepalive = 25;
  } // lib.optionalAttrs (p ? wg_endpoint_ip) {
    endpoint = "${p.wg_endpoint_ip}:51820";
  };

  mkClientPeer = _name: c: {
    publicKey = c.public_key;
    allowedIPs = [ "${c.wg_vpn_ip}/32" ];
  };
in
{
  networking.firewall.allowedUDPPorts = [ 51820 ];

  # Route the k8s LAN (10.0.0.0/24) into the WG mesh via this host. Lets
  # microVM workers (and the pods on them) reach 10.1.0.0/24 without each
  # needing its own mesh peer.
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;

  networking.wg-quick.interfaces.wg0 = {
    address = [ "${self.wg_vpn_ip}/24" ];
    listenPort = 51820;
    privateKeyFile = config.sops.secrets.wireguard-private-key.path;
    postUp = ''
      ${pkgs.iptables}/bin/iptables -A FORWARD -i br0 -o wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -o br0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o wg0 -j MASQUERADE
    '';
    preDown = ''
      ${pkgs.iptables}/bin/iptables -D FORWARD -i br0 -o wg0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -o br0 -j ACCEPT
      ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -s 10.0.0.0/24 -o wg0 -j MASQUERADE
    '';
    peers =
      (lib.mapAttrsToList mkMeshPeer otherPeers)
      ++ (lib.mapAttrsToList mkClientPeer clients);
  };
}

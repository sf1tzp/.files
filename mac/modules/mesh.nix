{ config, lib, pkgs, ... }:
# Mesh membership for a Mac: one wg-quick tunnel per estate, built from
# that estate's mesh/peers.json the way sfi/forts' modules/wireguard.nix
# builds a fort's. The estate repo is a flake input (flake = false), so
# the peer set is pinned in flake.lock and `nix flake update <estate>`
# is the Mac's "re-run fort wg-conf and paste".
#
# The private key never enters git or the store. nix-darwin's wg-quick
# module writes a conf that names a key FILE and loads it in PostUp
# (`wg set ... private-key`), and the key file is made here, on the host,
# at activation, the first time the tunnel is declared: `wg genkey` into
# a root-only file, printed nowhere. The public key is the one output:
#   sudo wg pubkey < /etc/wireguard/<interface>.key
# and that is what goes into the estate's peers.json, by PR.
let
  cfg = config.sfi.meshes;

  # The three tables of peers.json (sfi/forts docs/mesh.md), rendered as
  # wireguard.nix renders them: every other peer and every remote with
  # keepalive and, where it has one, an endpoint at its port; every
  # client with neither.
  mkMeshPeer = _name: p: {
    publicKey = p.public_key;
    allowedIPs = [ "${p.wg_vpn_ip}/32" ];
    persistentKeepalive = 25;
  } // lib.optionalAttrs (p ? wg_endpoint_ip) {
    endpoint = "${p.wg_endpoint_ip}:${toString (p.wg_endpoint_port or 51820)}";
  };
  mkClientPeer = _name: c: {
    publicKey = c.public_key;
    allowedIPs = [ "${c.wg_vpn_ip}/32" ];
  };

  render = _name: m:
    let
      data = builtins.fromJSON (builtins.readFile m.peersFile);
      notSelf = lib.filterAttrs (n: _: n != m.self);
      peers = notSelf (data.peers or { });
      clients = notSelf (data.clients or { });
      remotes = data.remotes or { };
    in
    {
      address = [ m.address ];
      listenPort = m.listenPort;
      privateKeyFile = m.privateKeyFile;
      peers = (lib.mapAttrsToList mkMeshPeer peers)
        ++ (lib.mapAttrsToList mkClientPeer clients)
        ++ (lib.mapAttrsToList mkMeshPeer remotes);
    };

  # The address is declared here, not read from peers.json, so the tunnel
  # builds before the estate's PR that registers this host lands (the
  # key must exist before the public key can be registered). Once the
  # entry exists, the two must agree.
  selfEntry = m:
    let data = builtins.fromJSON (builtins.readFile m.peersFile);
    in (data.peers or { }).${m.self} or (data.clients or { }).${m.self} or null;
  addressOf = m: lib.head (lib.splitString "/" m.address);

  meshOpts = { name, ... }: {
    options = {
      peersFile = lib.mkOption {
        type = lib.types.path;
        description = "The estate's mesh/peers.json, from its flake input.";
      };
      self = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName;
        description = "This host's name in peers.json; its own entry is skipped.";
      };
      interface = lib.mkOption {
        type = lib.types.str;
        default = "wg-${name}";
        description = "estate.toml's `interface`: the same name the forts give this mesh.";
      };
      address = lib.mkOption {
        type = lib.types.str;
        example = "10.2.0.96/24";
        description = "This host's address on the mesh, with the mesh's prefix length.";
      };
      listenPort = lib.mkOption {
        type = lib.types.int;
        default = 51820;
        description = "Where the forts dial this host; peers.json's wg_endpoint_port when not 51820.";
      };
      privateKeyFile = lib.mkOption {
        type = lib.types.str;
        default = "/etc/wireguard/wg-${name}.key";
        description = "Root-only, outside the store, made at activation if absent.";
      };
    };
  };
in
{
  options.sfi.meshes = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule meshOpts);
    default = { };
    description = "The estate meshes this Mac is on, by estate name.";
  };

  config = lib.mkIf (cfg != { }) {
    assertions = lib.mapAttrsToList
      (name: m:
        let e = selfEntry m; in {
          assertion = e == null || e.wg_vpn_ip == addressOf m;
          message = "sfi.meshes.${name}: address ${addressOf m} but peers.json gives ${m.self} ${e.wg_vpn_ip}";
        })
      cfg;

    networking.wg-quick.interfaces =
      lib.mapAttrs' (name: m: lib.nameValuePair m.interface (render name m)) cfg;

    # Before the launchd phase: wg-quick's PostUp loads the key, and a
    # missing file is a failed `up` that launchd does not retry.
    system.activationScripts.preActivation.text = lib.concatStringsSep "\n"
      (lib.mapAttrsToList
        (_name: m: ''
          if [ ! -f "${m.privateKeyFile}" ]; then
            echo "mesh: minting ${m.privateKeyFile} (the key stays on this host)"
            mkdir -p "$(dirname "${m.privateKeyFile}")"
            (umask 077; ${pkgs.wireguard-tools}/bin/wg genkey > "${m.privateKeyFile}")
          fi
        '')
        cfg);

    # After the launchd phase: the tunnel follows the conf. nix-darwin
    # reloads a daemon only when its plist changes, and a peers.json
    # change changes the conf, not the plist; and a first activation can
    # leave the daemon exited 1 with nothing to retry it. A running
    # tunnel is synced to the conf in place (wg syncconf: peers added
    # and removed, handshakes kept); a tunnel that is down gets its
    # daemon kicked. The key is re-asserted from its file, never printed.
    system.activationScripts.postActivation.text = lib.concatStringsSep "\n"
      (lib.mapAttrsToList
        (_name: m:
          let
            wg = "${pkgs.wireguard-tools}/bin/wg";
            wgQuick = "${pkgs.wireguard-tools}/bin/wg-quick";
            nameFile = "/var/run/wireguard/${m.interface}.name";
          in ''
            if [ -r "${nameFile}" ]; then
              dev=$(cat "${nameFile}")
              echo "mesh: syncing ${m.interface} ($dev) to its conf"
              ${wg} syncconf "$dev" <(${wgQuick} strip ${m.interface})
              ${wg} set "$dev" private-key "${m.privateKeyFile}"
            else
              echo "mesh: ${m.interface} is down, starting its daemon"
              launchctl kickstart -k system/org.nixos.wg-quick-${m.interface} || true
            fi
          '')
        cfg);
  };
}

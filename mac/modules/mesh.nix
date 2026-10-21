{ config, lib, pkgs, ... }:
# Mesh membership for a Mac: one wg-quick tunnel per estate, built from
# that estate's mesh/peers.json the way sfi/forts' modules/wireguard.nix
# builds a fort's. The estate repo is a flake input (flake = false), so
# the peer set is pinned in flake.lock and `nix flake update <estate>`
# is the Mac's "re-run fort wg-conf and paste".
#
# One key per host, as the forts: every mesh gets the same key, and the
# estates register one public key per host. The private key never
# enters git or the store. nix-darwin's wg-quick module writes a conf
# that names a key FILE and loads it in PostUp (`wg set ... private-key`),
# and the key file is made here, on the host, at activation, the first
# time a tunnel is declared: `wg genkey` into a root-only file, printed
# nowhere. The public key is the one output:
#   sudo wg pubkey < /etc/wireguard/mesh.key
# and that is what goes into every estate's peers.json, by PR.
#
# One listen port per host, too: two interfaces cannot bind the same UDP
# port. A client (no endpoint in peers.json; a Mac behind NAT) sets none
# and wg-quick picks a free one; a peer the forts dial sets the port its
# peers.json entry gives.
let
  cfg = config.sfi.meshes;
  wg = "${pkgs.wireguard-tools}/bin/wg";
  wgQuick = "${pkgs.wireguard-tools}/bin/wg-quick";

  # A launchd daemon that names a store path cannot start before the Nix
  # volume mounts, and launchd's answer to a missing executable at boot
  # is EX_CONFIG and no retry (the wg-quick plist keeps alive on a
  # successful exit only): the tunnel stays down until the next
  # activation. nix-darwin's own activate-system plist waits for the
  # store first; so do these.
  waitForStore = argv: [
    "/bin/sh"
    "-c"
    "/bin/wait4path /nix/store && exec ${lib.escapeShellArgs argv}"
  ];

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

  daemon = m: "org.nixos.wg-quick-${m.interface}";

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
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = ''
          Where the forts dial this host: peers.json's wg_endpoint_port
          (51820 when absent) for a host with a wg_endpoint_ip. Null for a
          client, and wg-quick picks a free port. One port per host: two
          meshes cannot share one.
        '';
      };
      privateKeyFile = lib.mkOption {
        type = lib.types.str;
        default = config.sfi.meshKeyFile;
        description = "This mesh's key. The default is the host's one key for every mesh.";
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

  options.sfi.meshKeyFile = lib.mkOption {
    type = lib.types.str;
    default = "/etc/wireguard/mesh.key";
    description = ''
      This host's one mesh private key, for every estate: root-only,
      outside the store, made at activation if absent. The estates
      register its public key, one per host.
    '';
  };

  config = lib.mkIf (cfg != { }) {
    assertions =
      (lib.mapAttrsToList
        (name: m:
          let e = selfEntry m; in {
            assertion = e == null || e.wg_vpn_ip == addressOf m;
            message = "sfi.meshes.${name}: address ${addressOf m} but peers.json gives ${m.self} ${e.wg_vpn_ip}";
          })
        cfg)
      ++ (lib.mapAttrsToList
        (name: m:
          let
            e = selfEntry m;
            dialed = e != null && e ? wg_endpoint_ip;
            port = if dialed then (e.wg_endpoint_port or 51820) else null;
          in {
            assertion = !dialed || m.listenPort == port;
            message = "sfi.meshes.${name}: peers.json dials ${m.self} at port ${toString port}, so listenPort must be ${toString port}";
          })
        cfg)
      ++ [{
        assertion =
          let ports = lib.filter (p: p != null) (lib.mapAttrsToList (_: m: m.listenPort) cfg);
          in lib.length ports == lib.length (lib.unique ports);
        message = "sfi.meshes: two meshes share a listenPort; one port per host";
      }];

    networking.wg-quick.interfaces =
      lib.mapAttrs' (name: m: lib.nameValuePair m.interface (render name m)) cfg;

    # nix-darwin's module names the store path as the daemon's program;
    # at boot that is a missing executable. Wait for the store instead.
    launchd.daemons = lib.mapAttrs'
      (_name: m: lib.nameValuePair "wg-quick-${m.interface}" {
        serviceConfig.ProgramArguments =
          lib.mkForce (waitForStore [ wgQuick "up" m.interface ]);
      })
      cfg;

    # Before the launchd phase: wg-quick's PostUp loads the key, and a
    # missing file is a failed `up` that launchd does not retry.
    system.activationScripts.preActivation.text = lib.concatStringsSep "\n"
      (map
        (keyFile: ''
          if [ ! -f "${keyFile}" ]; then
            echo "mesh: minting ${keyFile} (the key stays on this host)"
            mkdir -p "$(dirname "${keyFile}")"
            (umask 077; ${wg} genkey > "${keyFile}")
          fi
        '')
        (lib.unique (lib.mapAttrsToList (_: m: m.privateKeyFile) cfg)));

    # After the launchd phase: the tunnel follows the conf. nix-darwin
    # reloads a daemon only when its plist changes, and a peers.json
    # change changes the conf, not the plist; and a failed `up` leaves
    # the daemon exited with nothing to retry it. A running tunnel is
    # synced to the conf in place (wg syncconf: peers added and removed,
    # handshakes kept); a tunnel that is down gets its daemon loaded
    # afresh. Not `launchctl kickstart -k`: that blocks for good on a
    # service launchd parked after a failed spawn ("spawn scheduled",
    # EX_CONFIG), which is what a boot before the fix above left behind.
    # bootout drops that record; bootstrap loads the plist and RunAtLoad
    # starts it. The key is re-asserted from its file, never printed.
    system.activationScripts.postActivation.text = lib.concatStringsSep "\n"
      (lib.mapAttrsToList
        (_name: m:
          let nameFile = "/var/run/wireguard/${m.interface}.name"; in ''
            if [ -r "${nameFile}" ]; then
              dev=$(cat "${nameFile}")
              echo "mesh: syncing ${m.interface} ($dev) to its conf"
              ${wg} syncconf "$dev" <(${wgQuick} strip ${m.interface})
              ${wg} set "$dev" private-key "${m.privateKeyFile}"
            else
              echo "mesh: ${m.interface} is down, loading its daemon afresh"
              launchctl bootout system/${daemon m} 2>/dev/null || true
              launchctl bootstrap system /Library/LaunchDaemons/${daemon m}.plist || true
            fi
          '')
        cfg);
  };
}

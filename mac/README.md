# mac — the Macs, declared

nix-darwin plus home-manager over the `shell/` tree this repo has always
carried. The system half (packages, zsh, launchd, the Homebrew casks) is
nix; the user half is links from `$HOME` into this checkout, so the
profile, tmux, starship and the Claude Code files are edited here and
live at the next prompt, as before.

```
flake.nix               the inputs and one darwinConfigurations entry per Mac
hosts/macmini.nix       the host: platform, primary user, node_exporter as a launchd daemon
modules/packages.nix    the CLI set (what `brew leaves` held, minus casks and the retired six)
modules/shell.nix       zsh on
modules/homebrew.nix    taps and casks declared; cleanup staged
home/steven.nix         the links into shell/
```

## Apply on macmini

1. `brew services stop node_exporter` — the nix daemon takes :9100.
2. Build as yourself, then set the profile and activate as root:

   ```
   cd ~/.files/mac && nix build .#darwinConfigurations.macmini.system
   sudo nix-env -p /nix/var/nix/profiles/system --set "$(readlink ./result)"
   sudo ./result/sw/bin/darwin-rebuild activate
   ```

   The first time, before `darwin-rebuild` exists on the host, the build
   is `nix run nix-darwin/master#darwin-rebuild -- build --flake
   ~/.files/mac#<host>` as yourself, then the same two steps as root.

   Not `sudo darwin-rebuild switch`: that evaluates the flake as root,
   and root fetches the inputs. The estate inputs (below) are on
   gitea over ssh, and root has no key there. The build runs as you,
   where the key is; the two root steps are what `switch` does after
   its build. The profile step is not optional, and it comes first:
   `activate` alone runs the built system's activation and sets no
   profile, and nix-darwin's boot daemon (`org.nixos.activate-system`)
   re-activates whatever the profile names — at every boot, and in the
   middle of any activation that replaces its plist. That re-activation
   points `/etc/static` and `/run/current-system` at the profile's
   generation and deletes the `/etc` links the newer system made. On
   2026-10-21 the profile was eleven days behind and the wg-quick confs
   went that way, in the same second the activation had linked them.
   home-manager moves the hand-made links (`~/.zshrc`, `~/.claude/CLAUDE.md`, ...)
   aside as `*.hm-bak` and makes its own.
3. Open a new shell. `which sops age wg kubectl` must answer under
   `/run/current-system/sw/bin`. The profile puts Homebrew after nix.
4. `uv tool install fb-idb` — the idb client is not in nixpkgs; this is
   what pipx held.
5. Flip `homebrew.onActivation.cleanup` to `"uninstall"` and switch again.
   That removes the formulae and every cask off the list.

## What stays where

- **nix:** every CLI tool. `fort` comes from each estate's own flake
  (`nix run ./nixos#fort`), so it is not listed. Python is `python3`
  from nixpkgs plus `uv` for versions, venvs and tools; pyenv and pipx
  are gone.
- **Homebrew:** the casks, declared. A cask off the list is uninstalled on
  the next switch once cleanup is on.
- **by hand, still:** the WireGuard app's tunnels (one per estate), the
  Xcode install, `~/.config/nvim`, `~/gotea/bin` and `uv tool install fb-idb`.

## The meshes

A Mac joins an estate's mesh from here, not from the WireGuard app
(`modules/mesh.nix`). The estate repo is a flake input (`flake = false`),
its `mesh/peers.json` is read at build time, and nix-darwin's `wg-quick`
module runs the tunnel as a launchd daemon. The private key is a
root-only file the first switch mints on the host and nothing reads
back; the conf in the store names the file and never holds the key.
One key per host, as the forts: every mesh here loads the same file
(`sfi.meshKeyFile`), and every estate registers the same public key.
One listen port per host, too: two interfaces cannot bind one UDP port.
A client (a Mac behind NAT, no `wg_endpoint_ip` in peers.json) sets no
`listenPort` and wg-quick picks a free one; a host the forts dial sets
the port its peers.json entry gives, and the build refuses a mismatch.
The daemons wait for the Nix volume (`wait4path /nix/store`) before
they start: at boot the store mounts after launchd, and a daemon that
names a store path then is a missing executable launchd never retries.

```
sfi.meshes.staging = {
  peersFile = "${inputs.staging}/mesh/peers.json";
  interface = "wg-staging";      # estate.toml's interface
  address = "10.2.0.96/24";      # last octet follows the LAN address
};
```

To join a mesh:

1. Declare it in the host file, build, activate. The activation mints
   the key if the host has none yet.
2. `sudo wg pubkey < /etc/wireguard/mesh.key` — the one output
   (`sfi.meshKeyFile`; on macmini the file is `wg-staging.key`).
3. In the estate: a `clients.<host>` entry by hand (`wg_vpn_ip`, the
   public key) for a Mac the forts cannot dial, or a `peers.<host>` entry
   (plus `wg_endpoint_ip` = the LAN address, and `wg_endpoint_port`
   matching `listenPort`) for one they can; then `fort ssh-config
   --write`, `fort check --all`, PR.
4. After that PR merges: `nix flake update staging` here, build,
   activate. The forts pick the peer up on their own rebuild.

A later peers.json change is step 4 again: the activation syncs the
running tunnel to the new conf in place (`wg syncconf`), and loads the
daemon afresh (`launchctl bootout` then `bootstrap`) if the tunnel is
down. The live state is `sudo wg show`; it
redacts the key. On macOS the interface is a `utunN`, and only
`wg-quick` knows it as `wg-staging` (the map is
`/var/run/wireguard/wg-staging.name`, root-only), so `wg show wg-staging`
answers "No such file or directory" while the tunnel is up. wg-quick
warns that the conf is "world accessible": it is, by design, because it
holds no key.

## macbook-air

Not declared yet. Its brew list differs (full Xcode, the verify and
capture skills, the music apps), so it gets its own `hosts/` file and
its own package list rather than a copy of this one. The SF Mono nerd
font (tap `epk/epk`, cask `font-sf-mono-nerd-font`) dropped here with
Alacritty; if that machine's terminal wants it, it comes back there.

## The agent persona

A Claude Code session on a Mac writes to forge.streetfortress.cloud as
`sfi-agent`, not as you: the session's commits are sfi-agent's and
signed, its pushes use sfi-agent's key, its pull requests open under
sfi-agent. You review and merge as yourself, so branch protection and
approvals apply to the agent's work. Outside a session nothing changes:
your key, your login, your name.

The mechanism is one environment variable. `shell/config/claude-settings.json`
gives every session `SFI_AGENT=1` plus the git author, committer and
signing settings; `shell/config/ssh/sfi-agent.conf` (linked to
`~/.ssh/sfi-agent.conf`, included from `~/.ssh/config`'s first line)
matches on that variable and hands ssh the persona's key for the forge
alone. `tea` has no such switch: a session passes `--login sfi-agent`.

Once per Mac, after the activate:

1. Mint sfi-agent's token on the forge, as sfi-agent (Forgejo issues a
   token only to its own account): scopes `write:repository`,
   `write:issue`, `read:user`, `read:organization`.
2. `SFI_AGENT_TOKEN=… sfi-agent-bootstrap` (`shell/scripts`): generates
   `~/.ssh/sfi-agent` and the GPG key `sfi-agent <support@streetfortress.com>`
   in `~/.gnupg`, registers both on the account titled `agent-<host>`,
   through fj (forgejo-cli), stores the token in fj's login and adds the tea
   login `sfi-agent`. Without the token it generates and
   prints, and you register by hand.
3. `Include ~/.ssh/sfi-agent.conf` as the first line of `~/.ssh/config`.

The private halves stay on this Mac. gotea's agent-policy audits the
bundle (sfi/gotea#120); the fix for a drifted one is the bootstrap, not
`fort mint`.

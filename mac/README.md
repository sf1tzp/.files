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
2. Build as yourself and activate as root:

   ```
   cd ~/.files/mac && nix build .#darwinConfigurations.macmini.system
   sudo ./result/sw/bin/darwin-rebuild activate
   ```

   The first time, before `darwin-rebuild` exists on the host, the build
   is `nix run nix-darwin/master#darwin-rebuild -- build --flake
   ~/.files/mac#<host>` as yourself, then the same `activate` as root.

   Not `sudo darwin-rebuild switch`: that evaluates the flake as root,
   and root fetches the inputs. The estate inputs (below) are on
   gitea over ssh, and root has no key there. The build runs as you,
   where the key is; `activate` from the built system's own `sw/bin`
   sets the system profile to that exact path and runs its activation,
   which is what `switch` does after its build.
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

```
sfi.meshes.staging = {
  peersFile = "${inputs.staging}/mesh/peers.json";
  interface = "wg-staging";      # estate.toml's interface
  address = "10.2.0.96/24";      # last octet follows the LAN address
};
```

To join a mesh:

1. Declare it in the host file, build, activate. The activation mints the key.
2. `sudo wg pubkey < /etc/wireguard/wg-staging.key` — the one output.
3. In the estate: a `peers.<host>` entry by hand (`wg_vpn_ip`,
   `wg_endpoint_ip` = the LAN address, the public key), then
   `fort ssh-config --write`, `fort check --all`, PR.
4. After that PR merges: `nix flake update staging` here, build,
   activate. The forts pick the peer up on their own rebuild.

A later peers.json change is step 4 again: the activation syncs the
running tunnel to the new conf in place (`wg syncconf`), and starts the
daemon if the tunnel is down. The live state is `sudo wg show`; it
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

# darwin — the Macs, declared

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

1. `brew trust epk/epk` — Homebrew 7 refuses an untrusted third-party tap.
2. `brew services stop node_exporter` — the nix daemon takes :9100.
3. `sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake ~/.files/darwin#macmini`
   the first time; `sudo darwin-rebuild switch --flake ~/.files/darwin#macmini` after.
4. Open a new shell. `which sops age wg kubectl` must answer under
   `/run/current-system/sw/bin`. The profile puts Homebrew after nix.
5. Flip `homebrew.onActivation.cleanup` to `"uninstall"` and switch again.
   That removes the formulae and the six retired casks.

## What stays where

- **nix:** every CLI tool. `fort` comes from each estate's own flake
  (`nix run ./nixos#fort`), so it is not listed.
- **Homebrew:** the casks, declared. A cask off the list is uninstalled on
  the next switch once cleanup is on.
- **by hand, still:** the WireGuard app's tunnels (one per estate), the
  Xcode install, `~/.config/nvim` and `~/gotea/bin`.

## macbook-air

Not declared yet. Its brew list differs (full Xcode, the verify and
capture skills), so it gets its own `hosts/` file and its own package
list rather than a copy of this one.

{ inputs, lib, pkgs, ... }:
# The estate's CA roots (nixos/certs/ca-root.pem in sfi/estate-hub: the
# lofi lab CA, and the estate-hub Root CA that step-ca on sfi-central
# issues from, sfi/estate-hub#63) in the two places a Mac checks trust.
#
# 1. The bundle nix-darwin writes to /etc/ssl/certs/ca-certificates.crt.
#    That bundle is what NIX_SSL_CERT_FILE names, and nixpkgs' OpenSSL
#    reads that variable, so one entry covers nix's own fetchers and
#    nixpkgs' git alike: a flake input on git+https://gitea.zen.lofi/…
#    fetches without GIT_SSL_CAINFO in the environment (sfi/estate-hub#53
#    found the gap). Verified on macmini, 2026-10-22: the same `git
#    ls-remote` that failed on the plain bundle answered with the lab CA
#    appended; SSL_CERT_FILE alone did nothing.
#
# 2. The System keychain. Safari, Apple's curl and everything else on
#    Security.framework never read the file bundle; they read the
#    keychain. The activation below adds each root of the bundle to
#    /Library/Keychains/System.keychain as a trusted root, once: the
#    test is `security verify-cert -L` (local, no network), which
#    passes for a root that is present and trusted and fails otherwise,
#    so a root added by hand earlier is left alone and a new one in the
#    bundle is added on the next activation. The bundle is split here,
#    at build time, because add-trusted-cert reads one certificate per
#    file. Activation runs as root, so the admin trust domain (-d) needs
#    no prompt. A failed add is reported and does not fail the
#    activation.
#
# The source is the estate's copy, pinned like its peers file: `nix
# flake update estate-hub` is the rotation.
let
  bundle = "${inputs.estate-hub}/nixos/certs/ca-root.pem";
  # One store file per certificate in the bundle, in bundle order.
  roots = lib.imap1
    (i: pem: pkgs.writeText "estate-hub-root-${toString i}.pem"
      (lib.strings.trim pem + "\n-----END CERTIFICATE-----\n"))
    (lib.filter (s: lib.hasInfix "-----BEGIN CERTIFICATE-----" s)
      (lib.splitString "-----END CERTIFICATE-----" (builtins.readFile bundle)));
  security = "/usr/bin/security";
  keychain = "/Library/Keychains/System.keychain";
in
{
  security.pki.certificateFiles = [ bundle ];

  system.activationScripts.postActivation.text = lib.concatMapStringsSep "\n"
    (root: ''
      if ! ${security} verify-cert -c ${root} -L >/dev/null 2>&1; then
        echo "lab-ca: adding ${root} to the System keychain as a trusted root"
        ${security} add-trusted-cert -d -r trustRoot -k ${keychain} ${root} \
          || echo "lab-ca: add-trusted-cert failed for ${root}; add it by hand" >&2
      fi
    '')
    roots;
}

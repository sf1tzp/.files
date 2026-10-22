{ inputs, ... }:
# The lab CA (lofi lab CA, the step-ca root every lab service's
# certificate chains to) in the bundle nix-darwin writes to
# /etc/ssl/certs/ca-certificates.crt. That bundle is what
# NIX_SSL_CERT_FILE names, and nixpkgs' OpenSSL reads that variable, so
# one entry covers nix's own fetchers and nixpkgs' git alike: a flake
# input on git+https://gitea.zen.lofi/… fetches without GIT_SSL_CAINFO
# in the environment (sfi/estate-hub#53 found the gap). Verified on
# macmini, 2026-10-22: the same `git ls-remote` that failed on the plain
# bundle answered with the lab CA appended; SSL_CERT_FILE alone did
# nothing.
#
# The source is the estate's copy, pinned like its peers file: `nix
# flake update estate-hub` is the rotation. The macOS keychain is not
# touched — Safari and Apple's curl still see the lab certs as
# untrusted; that is a `security add-trusted-cert` by hand, if wanted.
{
  security.pki.certificateFiles = [ "${inputs.estate-hub}/nixos/certs/ca-root.pem" ];
}

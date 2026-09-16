# sops-nix wiring for zenbook: decrypts secrets/zenbook.yaml with a standalone
# user age key. Secret declarations here are the zenbook-only ones; k3s-token is
# declared by modules/k3s-server.nix.
{ ... }:

{
  sops = {
    defaultSopsFile = ../../secrets/zenbook.yaml;

    age.sshKeyPaths = [ ]; # Don't derive from SSH host keys
    age.keyFile = "/home/steven/.config/sops/age/keys.txt";

    secrets = {
      wireguard-private-key = {
        mode = "0400";
        owner = "root";
      };
      restic-password = {
        # Restic repository encryption password — guard this carefully.
        # Without it, backups cannot be decrypted.
        mode = "0400";
        owner = "root";
      };
      restic-s3-env-rustfs = {
        # AWS_ACCESS_KEY_ID=...\nAWS_SECRET_ACCESS_KEY=...
        mode = "0400";
        owner = "root";
      };
      restic-s3-env-offsite = {
        # AWS_ACCESS_KEY_ID=...\nAWS_SECRET_ACCESS_KEY=...
        mode = "0400";
        owner = "root";
      };
      restic-s3-env-b2 = {
        # AWS_ACCESS_KEY_ID=...\nAWS_SECRET_ACCESS_KEY=...
        # The B2 application key for this host: both backup buckets,
        # namePrefix zenbook/, and NO deleteFiles. sops-nix materializes
        # only what is declared here, so this line and the value in
        # secrets/zenbook.yaml must land together — a declared-but-absent
        # key fails activation.
        mode = "0400";
        owner = "root";
      };
    };
  };
}

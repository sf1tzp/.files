# Gitea

Gittea, configured to run in my homelab infra. Featuring:
- Upstream Github Mirroring
- CI/CD Run
- Container Registry

## Source Code

[Main helm chart](https://gitea.com/gitea/helm-gitea/)
[Actions helm chart](https://gitea.com/gitea/helm-actions/)

## Usage

### Action Runners
1. Get a runner token from Gitea: Site Administration > Runners > Create new Runner"
2. Run: just deploy-actions <token>"
3. Copy gitea/ci-workflow.example.yaml to .gitea/workflows/ci.yaml in your GitHub repos

### Container Registry
1. In Gitea web UI, create a PAT with write:packages scope and add it as a Repo or Organization Actions secret named REGISTRY_TOKEN
2. Actions then use {{ secrets.REGISTRY_TOKEN }} to authenticate
3. Distribute tokens for other client use (eg ImagePullSecrets)

### Actions Prod Deployments

#### SSH Configuration

1. Generate a runner-only keypair (don't reuse a personal key):
```bash
ssh-keygen -t ed25519 -N '' -C 'gitea-actions-runner' -f /tmp/runner_ed25519
```

2. Capture target host keys for `known_hosts` (avoids first-connect prompts):
```bash
ssh-keyscan -t ed25519 web2.streetfortress.cloud > /tmp/runner_known_hosts
```

3. Edit the SOPS-encrypted Secret and paste in the values:
```bash
sops k8s/gitea-actions/secrets.yaml
```
Fill in:
- `id_ed25519`: contents of `/tmp/runner_ed25519` (the private key)
- `known_hosts`: contents of `/tmp/runner_known_hosts`
- `config`: per-host SSH config, e.g.
  ```
  Host web2.streetfortress.cloud
      User <deploy-user>
      IdentityFile ~/.ssh/id_ed25519
      StrictHostKeyChecking yes
  ```

4. Install the public key on the deploy target:
```bash
ssh-copy-id -i /tmp/runner_ed25519.pub <deploy-user>@web2.streetfortress.cloud
# or append /tmp/runner_ed25519.pub manually to ~/.ssh/authorized_keys
```

5. Apply the Secret and roll the runner pods so the new mount is picked up:
```bash
sops -d k8s/gitea-actions/secrets.yaml | kubectl apply -f -
kubectl -n gitea-actions rollout restart statefulset/gitea-actions-act-runner
```

6. Wipe the temp files:
```bash
shred -u /tmp/runner_ed25519 /tmp/runner_ed25519.pub /tmp/runner_known_hosts
```

#### SOPS Configuration

1. Generate a per-repo age recipient (one keypair per repo so a leaked CI token only decrypts that repo's secrets):
```bash
age-keygen -o /tmp/repo_age.txt
# Public key (recipient) is printed on stderr; private key is in the file.
```

2. Add the recipient to the repo's `.sops.yaml` and re-encrypt existing secrets:
```bash
# In the target repo (e.g. auth-service):
$EDITOR .sops.yaml   # add recipient under creation_rules
sops updatekeys secrets/web2.streetfortress.cloud.env
```

3. Add the **private** key as a Gitea repo-level Actions secret named `SOPS_AGE_KEY` (Settings > Actions > Secrets). Paste the full file contents (`AGE-SECRET-KEY-...`).

4. Wipe the temp file:
```bash
shred -u /tmp/repo_age.txt
```

> Note: the runner image's entrypoint writes `$SOPS_AGE_KEY` to `~/.config/sops/age/keys.txt` at job start, so workflows just reference `${{ secrets.SOPS_AGE_KEY }}` as step env.


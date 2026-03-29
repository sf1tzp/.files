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

### Mirror Congiruation
1. Get a Github PAT for private repo access
2. Run: just set-github-pat <your-github-pat>
3. Run: just mirror <github-user> repo1 repo2

### Container Registry
1. In Gitea web UI, create a PAT with write:packages scope and add it as a repo Actions secret named REGISTRY_TOKEN
2. Actions then use {{ secrets.REGISTRY_TOKEN }} to authenticate
3. Distribute tokens for other client use (eg ImagePullSecrets)

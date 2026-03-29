#!/usr/bin/env bash
# Create pull mirrors in Gitea for GitHub repositories.
# Usage: mirror.sh <github-username> <repo1> [repo2] ...
#
# Requires kubectl access to the gitea namespace for reading secrets.

set -euo pipefail

if [ $# -lt 2 ]; then
    echo "Usage: $0 <github-username> <repo1> [repo2] ..."
    exit 1
fi

GITHUB_USER="$1"; shift
REPOS=("$@")

GITEA_URL="${GITEA_URL:-http://gitea.zen.lofi}"

# Read credentials from k8s secrets
GITEA_USER=$(kubectl get secret gitea-admin -n gitea -o jsonpath='{.data.username}' | base64 -d)
GITEA_PASS=$(kubectl get secret gitea-admin -n gitea -o jsonpath='{.data.password}' | base64 -d)
GITHUB_TOKEN=$(kubectl get secret github-pat -n gitea -o jsonpath='{.data.token}' | base64 -d 2>/dev/null) || GITHUB_TOKEN=""

if [ -z "$GITHUB_TOKEN" ]; then
    echo "Warning: github-pat secret not found, private repos will fail."
    echo "Run: just set-github-pat <token>"
fi

for REPO in "${REPOS[@]}"; do
    echo "Mirroring ${GITHUB_USER}/${REPO}..."

    BODY=$(cat <<EOF
{
    "clone_addr": "https://github.com/${GITHUB_USER}/${REPO}.git",
    "repo_name": "${REPO}",
    "repo_owner": "${GITEA_USER}",
    "mirror": true,
    "service": "github",
    "auth_token": "${GITHUB_TOKEN}"
}
EOF
)

    HTTP_CODE=$(curl -s -o /tmp/mirror-response.json -w "%{http_code}" \
        -X POST "${GITEA_URL}/api/v1/repos/migrate" \
        -u "${GITEA_USER}:${GITEA_PASS}" \
        -H "Content-Type: application/json" \
        -d "$BODY")

    case "$HTTP_CODE" in
        201) echo "  -> Created mirror for ${REPO}" ;;
        409) echo "  -> Mirror already exists for ${REPO}, skipping" ;;
        *)   echo "  -> Failed (HTTP ${HTTP_CODE}): $(cat /tmp/mirror-response.json)" ;;
    esac
done

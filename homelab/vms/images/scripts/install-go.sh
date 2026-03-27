#!/bin/bash
set -euo pipefail

# Installs Go to /usr/local/go.
# Expects GO_VERSION env var to be set.

echo "=== Installing Go ${GO_VERSION} ==="

curl -fsSL "https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz
tar -C /usr/local -xzf /tmp/go.tar.gz
rm -f /tmp/go.tar.gz

echo "=== Go installation complete ==="

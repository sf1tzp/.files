#!/usr/bin/env bash
set -euo pipefail

WORKERS=(k8s-worker-1 k8s-worker-2)

echo "==> Stopping worker VMs..."
for w in "${WORKERS[@]}"; do
  sudo systemctl stop "microvm@${w}" 2>/dev/null && echo "    Stopped ${w}" || echo "    ${w} already stopped"
done

echo "==> Stopping k3s control plane..."
sudo systemctl stop k3s 2>/dev/null && echo "    Stopped k3s" || echo "    k3s already stopped"

echo "==> Wiping control plane state..."
sudo rm -rf /var/lib/rancher/k3s/server/db
echo "    Removed /var/lib/rancher/k3s/server/db"

echo "==> Wiping worker VM persistent volumes..."
for w in "${WORKERS[@]}"; do
  img="/var/lib/microvms/${w}/${w}-var.img"
  if [ -f "$img" ]; then
    sudo rm -f "$img"
    echo "    Removed ${img}"
  else
    echo "    ${img} not found, skipping"
  fi
done

echo "==> Starting k3s control plane..."
sudo systemctl start k3s
echo "    Waiting for k3s to become ready..."
until sudo k3s kubectl get nodes &>/dev/null; do
  sleep 2
done
echo "    Control plane is ready"

echo "==> Starting worker VMs..."
for w in "${WORKERS[@]}"; do
  sudo systemctl start "microvm@${w}"
  echo "    Started ${w}"
done

echo "==> Waiting for workers to join..."
expected=$(( ${#WORKERS[@]} + 1 )) # workers + control plane
for i in $(seq 1 60); do
  ready=$(sudo k3s kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready" || true)
  if [ "$ready" -ge "$expected" ]; then
    echo "==> All ${expected} nodes are Ready:"
    sudo k3s kubectl get nodes -o wide
    exit 0
  fi
  sleep 5
done

echo "==> Timed out waiting for all nodes. Current status:"
sudo k3s kubectl get nodes -o wide
exit 1

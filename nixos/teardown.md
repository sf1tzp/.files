  Full steps:

  # 1. Stop everything
  sudo systemctl stop k3s
  sudo systemctl stop microvm@k8s-worker-1
  sudo systemctl stop microvm@k8s-worker-2

  # 2. Wipe control plane state
  sudo rm -rf /var/lib/rancher/k3s/server/db

  # 3. Wipe worker VM persistent volumes (k3s agent state lives in /var)
  sudo rm -f /var/lib/microvms/k8s-worker-1/k8s-worker-1-var.img
  sudo rm -f /var/lib/microvms/k8s-worker-2/k8s-worker-2-var.img

  # 4. Start control plane first, let it fully bootstrap
  sudo systemctl start k3s

  # 5. Once k3s is healthy, start workers
  sudo systemctl start microvm@k8s-worker-1
  sudo systemctl start microvm@k8s-worker-2

  A couple of notes:
  - The worker volume images will be recreated automatically on next VM boot (per the volumes config in k3s-cluster.nix)
  - Wait for sudo k3s kubectl get nodes to show the server as Ready before starting the workers
  - You may also want to verify the sops token decrypted correctly first: sudo cat /run/secrets/k3s-token



#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ACTION="${1:-}"
FLAG="${2:-}"
COLIMA_PROFILE="kind-lab"

usage() {
  echo "Usage: $0 <create|destroy> [--vm]"
  echo "  destroy --vm  also delete the '$COLIMA_PROFILE' colima VM"
  exit 1
}

start_colima() {
  if ! colima status --profile "$COLIMA_PROFILE" &>/dev/null; then
    colima start --profile "$COLIMA_PROFILE" --cpu 4 --memory 8 --disk 60
  else
    echo "Colima profile '$COLIMA_PROFILE' already running"
  fi
}

create_cluster() {
  # Force a fresh pull of the node image: a stale/incomplete local cache
  # causes "content digest ... not found" when kind loads it into containerd.
  docker images -q kindest/node | xargs -r docker rmi -f
  kind create cluster --config=kind-config.yaml
}

install_cilium() {
  helm repo add cilium https://helm.cilium.io/
  helm install cilium cilium/cilium --version 1.19.5 \
   --namespace kube-system \
   --set image.pullPolicy=IfNotPresent \
   --set ipam.mode=kubernetes
}

case "$ACTION" in
  create)
    start_colima
    existing_nodes="$(docker ps -a --filter label=io.x-k8s.kind.cluster=kind --format '{{.Names}}')"
    if [ -z "$existing_nodes" ]; then
      create_cluster
    else
      echo "Cluster 'kind' already exists, ensuring nodes are running"
      if ! echo "$existing_nodes" | xargs -r docker start; then
        echo "Existing nodes are unhealthy, recreating cluster"
        kind delete cluster --name kind
        create_cluster
      fi
    fi
    kind export kubeconfig --name kind
    kubectl cluster-info --context kind-kind
    install_cilium
    ;;
  destroy)
    kind delete cluster --name kind
    if [ "$FLAG" = "--vm" ]; then
      colima delete --profile "$COLIMA_PROFILE" -f
    fi
    ;;
  *)
    usage
    ;;
esac

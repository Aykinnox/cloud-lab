#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

RELEASE="otel"
NAMESPACE="otel-demo"
CHART_DIR="./opentelemetry-demo"
VALUES="$CHART_DIR/values.yaml"
NS_MANIFEST="./ns-otel-demo.yaml"

ACTION="${1:-install}"

usage() {
  echo "Usage: $0 <install|uninstall>"
  echo "  install    (default) create the namespace and install/upgrade the release"
  echo "  uninstall  remove the release and the namespace"
  exit 1
}

for bin in helm kubectl; do
  command -v "$bin" >/dev/null 2>&1 || { echo "error: '$bin' not found in PATH" >&2; exit 1; }
done

add_repos() {
  helm repo add opentelemetry https://open-telemetry.github.io/opentelemetry-helm-charts --force-update
  helm repo add jaeger       https://jaegertracing.github.io/helm-charts                --force-update
  helm repo add prometheus   https://prometheus-community.github.io/helm-charts         --force-update
  helm repo add grafana      https://grafana-community.github.io/helm-charts            --force-update
  helm repo add opensearch   https://opensearch-project.github.io/helm-charts/          --force-update
  helm repo update
}

install() {
  add_repos
  kubectl apply -f "$NS_MANIFEST"
  helm upgrade --install "$RELEASE" "$CHART_DIR" -f "$VALUES" -n "$NAMESPACE"
}

uninstall() {
  helm uninstall "$RELEASE" -n "$NAMESPACE" 2>/dev/null || echo "release '$RELEASE' not found, skipping"
  kubectl delete -f "$NS_MANIFEST" --ignore-not-found
}

case "$ACTION" in
  install)   install ;;
  uninstall) uninstall ;;
  -h|--help) usage ;;
  *)         echo "error: unknown action '$ACTION'" >&2; usage ;;
esac

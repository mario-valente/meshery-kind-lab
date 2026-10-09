#!/usr/bin/env bash
# Sobe 2 clusters kind, instala Meshery no meshery-a e gera kubeconfig com os 2 clusters.
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p out

for c in a b; do
  kind get clusters | grep -qx "meshery-$c" || kind create cluster --config "kind/cluster-$c.yaml"
done

for c in a b; do
  kubectl --context "kind-meshery-$c" apply -f manifests/sample-app.yaml
done

helm repo add meshery https://meshery.io/charts/ >/dev/null 2>&1 || true
helm repo update meshery >/dev/null
helm upgrade --install meshery meshery/meshery \
  --kube-context kind-meshery-a -n meshery --create-namespace \
  --set env.PROVIDER=None \
  --set service.type=NodePort \
  --wait --timeout 10m

kubectl --context kind-meshery-a -n meshery patch svc meshery --type=json \
  -p='[{"op":"replace","path":"/spec/ports/0/nodePort","value":30081}]'

# Kubeconfig "internal": endpoints <cluster>-control-plane:6443 na rede docker "kind",
# alcançáveis de dentro do pod do Meshery. É ESTE arquivo que deve ser enviado na UI.
kind get kubeconfig --internal --name meshery-a > out/a.yaml
kind get kubeconfig --internal --name meshery-b > out/b.yaml
KUBECONFIG=out/a.yaml:out/b.yaml kubectl config view --flatten > out/kubeconfig-internal.yaml
rm out/a.yaml out/b.yaml

# Registra os 2 clusters no Meshery (provider None = sem login)
for i in $(seq 1 30); do curl -sf -o /dev/null http://localhost:9081/healthz/ready && break; sleep 5; done
curl -s -c out/cookies -o /dev/null "http://localhost:9081/api/user/token?provider=None"
curl -s -b out/cookies -o /dev/null -X POST -F "k8sfile=@out/kubeconfig-internal.yaml" \
  http://localhost:9081/api/system/kubernetes && echo "kubeconfig enviado ao Meshery"

echo
echo "Meshery UI: http://localhost:9081"
echo "Conexoes: Lifecycle > Connections (kind-meshery-a e kind-meshery-b)"

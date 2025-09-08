#!/usr/bin/env bash
set -e

# 引数の確認
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <domain>"
  echo "Example: $0 example.com"
  exit 1
fi

DOMAIN="argocd.$1"

# Helmリポジトリの追加
helm repo add eks https://aws.github.io/eks-charts
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
helm repo update

# Helmインストールまたはアップグレード: aws-load-balancer-controller
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=webapp \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# aws-load-balancer-controllerの起動を待つ
kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system

# Helmインストールまたはアップグレード: external-dns
helm upgrade --install external-dns external-dns/external-dns \
  --namespace external-dns \
  --set provider.name=aws \
  --set serviceAccount.create=false \
  --set serviceAccount.name=external-dns-sa \
  --set policy=sync \
  --set txtOwnerId=argocd \
  --set "domainFilters[0]=${DOMAIN}"

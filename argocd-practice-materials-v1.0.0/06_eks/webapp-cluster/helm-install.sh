#!/usr/bin/env bash
set -e

# 引数の確認
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <domain>"
  echo "Example: $0 example.com"
  exit 1
fi

DOMAIN="$1"
EXCLUDE_DOMAIN="argocd.${DOMAIN}"

# Helmリポジトリの追加
helm repo add eks https://aws.github.io/eks-charts
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/
# helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update

# Helmインストールまたはアップグレード: aws-load-balancer-controller
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=webapp \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

# Helmインストールまたはアップグレード: csi-secrets-store
helm upgrade --install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system \
  --set syncSecret.enabled=true \
  --set enableSecretRotation=true \
  --set rotationPollInterval=3600s

# Helmインストールまたはアップグレード: secrets-provider-aws
helm upgrade --install secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws \
  --namespace kube-system

# Helmインストールまたはアップグレード: reloader
helm upgrade --install reloader stakater/reloader \
  --namespace kube-system

# aws-load-balancer-controllerの起動を待つ
kubectl wait --for=condition=available --timeout=300s deployment/aws-load-balancer-controller -n kube-system

# Helmインストールまたはアップグレード: external-dns
helm upgrade --install external-dns external-dns/external-dns \
  --namespace external-dns \
  --set provider.name=aws \
  --set serviceAccount.create=false \
  --set serviceAccount.name=external-dns-sa \
  --set policy=sync \
  --set txtOwnerId=webapp \
  --set "domainFilters[0]=${DOMAIN}" \
  --set "excludeDomains[0]=${EXCLUDE_DOMAIN}"

# Helmインストールまたはアップグレード: metrics-server
# eksctl v0.201.0 から metrics-server は自動でインストールされるようになりました
# https://github.com/eksctl-io/eksctl/releases/tag/v0.201.0
# helm upgrade --install metrics-server metrics-server/metrics-server \
#   --namespace kube-system

# Helmインストールまたはアップグレード: cluster-autoscaler
helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler \
  --namespace kube-system \
  --set cloudProvider=aws \
  --set awsRegion=ap-northeast-1 \
  --set image.tag=v1.30.0 \
  --set autoDiscovery.clusterName=webapp \
  --set rbac.serviceAccount.create=false \
  --set rbac.serviceAccount.name=cluster-autoscaler \
  --set extraArgs.scale-down-unneeded-time=1m \
  --set extraArgs.scale-down-delay-after-add=1m

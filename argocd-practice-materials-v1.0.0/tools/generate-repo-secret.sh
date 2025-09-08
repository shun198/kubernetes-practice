#!/usr/bin/env bash

# デフォルト値
DEFAULT_NAME="new-repository-secret"
DEFAULT_NAMESPACE="argocd"
DEFAULT_PROJECT="default"
DEFAULT_URL=""

# ヘルプ関数
function print_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -n, --name          Secret name (default: ${DEFAULT_NAME})"
  echo "  -s, --namespace     Kubernetes namespace (default: ${DEFAULT_NAMESPACE})"
  echo "  -p, --project       Project name (default: ${DEFAULT_PROJECT})"
  echo "  -u, --url           Repository URL (required, will be Base64 encoded)"
  echo "  -h, --help          Show this help message and exit"
  echo ""
  echo "Example:"
  echo "  $0 \\"
  echo "    --name my-repository-secret \\"
  echo "    --namespace argocd \\"
  echo "    --project my-project \\"
  echo "    --url https://github.com/example/my-repo.git"
}

# オプションの初期化
NAME="${DEFAULT_NAME}"
NAMESPACE="${DEFAULT_NAMESPACE}"
PROJECT="${DEFAULT_PROJECT}"
URL=""

# オプションのパース
while [[ $# -gt 0 ]]; do
  key="$1"

  case ${key} in
    -n|--name)
      NAME="$2"
      shift 2
      ;;
    -s|--namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -p|--project)
      PROJECT="$2"
      shift 2
      ;;
    -u|--url)
      URL="$2"
      shift 2
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    *)
      echo "Invalid option: $1"
      print_help
      exit 1
      ;;
  esac
done

# 必須パラメータが指定されているかチェック
if [ -z "${URL}" ]; then
  echo "Error: --url is a required option."
  print_help
  exit 1
fi

# Base64エンコード
URL_BASE64=$(echo -n "${URL}" | base64)
PROJECT_BASE64=$(echo -n "${PROJECT}" | base64)

# YAMLの出力
cat <<EOF
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: ${NAME}
  namespace: ${NAMESPACE}
  labels:
    argocd.argoproj.io/secret-type: repository
data:
  project: ${PROJECT_BASE64}
  url: ${URL_BASE64}
EOF

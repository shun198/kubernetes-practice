#!/usr/bin/env bash

# デフォルト値
DEFAULT_NAME="github-repocred"
DEFAULT_NAMESPACE="argocd"

# ヘルプ関数
function print_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -n, --name                        Secret name (default: ${DEFAULT_NAME})"
  echo "  -s, --namespace                   Kubernetes namespace (default: ${DEFAULT_NAMESPACE})"
  echo "  -u, --url                         Repository or organization URL (required, will be Base64 encoded)"
  echo "  -i, --github-app-id               GitHub App ID (required, will be Base64 encoded)"
  echo "  -I, --github-app-installation-id  GitHub App Installation ID (required, will be Base64 encoded)"
  echo "  -k, --private-key                 Path to the private key file (required, Base64 encoded content will be used)"
  echo "  -h, --help                        Show this help message and exit"
  echo ""
  echo "Example:"
  echo "  $0 \\"
  echo "    --name github-repocred \\"
  echo "    --namespace argocd \\"
  echo "    --url https://github.com/argoproj \\"
  echo "    --github-app-id 123456 \\"
  echo "    --github-app-installation-id 12345678 \\"
  echo "    --private-key /path/to/private-key.pem"
}

# オプションの初期化
NAME="${DEFAULT_NAME}"
NAMESPACE="${DEFAULT_NAMESPACE}"
URL=""
GITHUB_APP_ID=""
GITHUB_APP_INSTALLATION_ID=""
PRIVATE_KEY_FILE=""
GITHUB_APP_PRIVATE_KEY=""

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
    -u|--url)
      URL="$2"
      shift 2
      ;;
    -i|--github-app-id)
      GITHUB_APP_ID="$2"
      shift 2
      ;;
    -I|--github-app-installation-id)
      GITHUB_APP_INSTALLATION_ID="$2"
      shift 2
      ;;
    -k|--private-key)
      PRIVATE_KEY_FILE="$2"
      if [ -f "${PRIVATE_KEY_FILE}" ]; then
        GITHUB_APP_PRIVATE_KEY=$(cat "${PRIVATE_KEY_FILE}" | base64 -w 0)
      else
        echo "Private key file not found: ${PRIVATE_KEY_FILE}"
        exit 1
      fi
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
if [ -z "${URL}" ] || [ -z "${GITHUB_APP_ID}" ] || [ -z "${GITHUB_APP_INSTALLATION_ID}" ] || [ -z "${GITHUB_APP_PRIVATE_KEY}" ]; then
  echo "Error: --url, --github-app-id, --github-app-installation-id, and --private-key are required options."
  print_help
  exit 1
fi

# Base64エンコード
URL_BASE64=$(echo -n "${URL}" | base64 -w 0)
GITHUB_APP_ID_BASE64=$(echo -n "${GITHUB_APP_ID}" | base64 -w 0)
GITHUB_APP_INSTALLATION_ID_BASE64=$(echo -n "${GITHUB_APP_INSTALLATION_ID}" | base64 -w 0)

# YAMLの出力
cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${NAME}
  namespace: ${NAMESPACE}
  labels:
    argocd.argoproj.io/secret-type: repo-creds
data:
  url: ${URL_BASE64}
  githubAppID: ${GITHUB_APP_ID_BASE64}
  githubAppInstallationID: ${GITHUB_APP_INSTALLATION_ID_BASE64}
  githubAppPrivateKey: ${GITHUB_APP_PRIVATE_KEY}
EOF

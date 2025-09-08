#!/usr/bin/env bash

# デフォルト値
DEFAULT_NAME="apps-manifests-repository"
DEFAULT_NAMESPACE="argocd"
DEFAULT_PROJECT="apps-management"
DEFAULT_URL="https://github.com/example/example-argocd-apps.git"
DEFAULT_TYPE="git"

# ヘルプ関数
function print_help() {
  echo "Usage: $0 [options]"
  echo ""
  echo "Options:"
  echo "  -n, --name                        Secret name (default: ${DEFAULT_NAME})"
  echo "  -s, --namespace                   Kubernetes namespace (default: ${DEFAULT_NAMESPACE})"
  echo "  -p, --project                     Project name (default: ${DEFAULT_PROJECT})"
  echo "  -u, --url                         Repository URL (required, will be Base64 encoded)"
  echo "  -t, --type                        Repository type (default: ${DEFAULT_TYPE}, will be Base64 encoded)"
  echo "  -i, --github-app-id               GitHub App ID (required, will be Base64 encoded)"
  echo "  -I, --github-app-installation-id  GitHub App Installation ID (required, will be Base64 encoded)"
  echo "  -k, --private-key                 Path to the private key file (Base64 encoded content will be used) (required)"
  echo "  -h, --help                        Show this help message and exit"
}

# オプションの初期化
NAME="${DEFAULT_NAME}"
NAMESPACE="${DEFAULT_NAMESPACE}"
PROJECT="${DEFAULT_PROJECT}"
URL=""
TYPE="${DEFAULT_TYPE}"
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
    -p|--project)
    PROJECT="$2"
    shift 2
    ;;
    -u|--url)
    URL="$2"
    shift 2
    ;;
    -t|--type)
    TYPE="$2"
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
      GITHUB_APP_PRIVATE_KEY=$(cat "${PRIVATE_KEY_FILE}" | base64)
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

# Base64エンコード
PROJECT_BASE64=$(echo -n "${PROJECT}" | base64)
URL_BASE64=$(echo -n "${URL}" | base64)
TYPE_BASE64=$(echo -n "${TYPE}" | base64)
GITHUB_APP_ID_BASE64=$(echo -n "${GITHUB_APP_ID}" | base64)
GITHUB_APP_INSTALLATION_ID_BASE64=$(echo -n "${GITHUB_APP_INSTALLATION_ID}" | base64)

# 必須パラメータが指定されているかチェック
if [ -z "${URL}" ] || [ -z "${GITHUB_APP_ID}" ] || [ -z "${GITHUB_APP_INSTALLATION_ID}" ] || [ -z "${GITHUB_APP_PRIVATE_KEY}" ]; then
  echo "Error: --url, --github-app-id, --github-app-installation-id, and --private-key are required options."
  print_help
  exit 1
fi

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
  # echo -n ${PROJECT} | base64
  project: ${PROJECT_BASE64}

  # 各アプリケーションの ArgoCD 用の manifests が管理されているリポジトリを指定する
  # echo -n '${URL}' | base64
  url: ${URL_BASE64}

  # echo -n ${TYPE} | base64
  type: ${TYPE_BASE64}

  # echo -n ${GITHUB_APP_ID} | base64
  githubAppID: ${GITHUB_APP_ID_BASE64}

  # GitHub App installation ID について
  # https://github.com/settings/installations
  # Configure ボタンを押した後のURLの数字
  #
  # 例：以下の場合は ${GITHUB_APP_INSTALLATION_ID} が GitHub App installation ID
  # https://github.com/settings/installations/${GITHUB_APP_INSTALLATION_ID}
  #
  # echo -n ${GITHUB_APP_INSTALLATION_ID} | base64
  githubAppInstallationID: ${GITHUB_APP_INSTALLATION_ID_BASE64}

  # cat ${PRIVATE_KEY_FILE} | base64
  githubAppPrivateKey: ${GITHUB_APP_PRIVATE_KEY}
EOF


#!/usr/bin/env bash

# デフォルト値
CLUSTER_TYPE=""
CONTEXT_NAME=""

# ヘルプメッセージ
function show_help {
  echo "Usage: $0 --cluster-type <minikube|kind> --context-name <CONTEXT_NAME>"
  echo
  echo "Options:"
  echo "  --cluster-type, -t  Type of the cluster (minikube or kind)"
  echo "  --context-name, -c  Name of the kubectl context"
  echo "  --help, -h          Show this help message"
  echo
  echo "Examples:"
  echo "  $0 --cluster-type minikube --context-name minikube"
  echo "  $0 -t kind -c kind-kind"
  echo
  echo "Applying Kubernetes resources from script output:"
  echo "  $0 --cluster-type <minikube|kind> --context-name <CONTEXT_NAME> | kubectl apply --context <CONTEXT_NAME> -f -"
  echo
  echo "Examples:"
  echo "  $0 --cluster-type minikube --context-name minikube | kubectl apply --context minikube -f -"
  echo "  $0 -t kind -c kind-kind | kubectl apply --context kind-kind -f -"
}

# 引数の解析
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --cluster-type|-t) CLUSTER_TYPE="$2"; shift ;;
    --context-name|-c) CONTEXT_NAME="$2"; shift ;;
    --help|-h) show_help; exit 0 ;;
    *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
  esac
  shift
done

# 引数のチェック
if [[ -z "$CLUSTER_TYPE" || -z "$CONTEXT_NAME" ]]; then
  echo "Error: Both --cluster-type and --context-name must be provided."
  show_help
  exit 1
fi

# 変数の設定
SECRET_NAME="${CONTEXT_NAME}-cluster-secret"
NAMESPACE="argocd"

# クラスターのサーバーアドレスを取得
if [[ "${CLUSTER_TYPE}" == "minikube" ]]; then
  SERVER="https://${MINIKUBE_IP}:8443"
  MINIKUBE_IP=$(minikube ip --profile ${CONTEXT_NAME} 2>&1)
  # 引数のチェック
  if [[ $? -ne 0 ]]; then
    echo "Error: Could not retrieve Minikube IP"
    echo -e "${MINIKUBE_IP}"
    exit 1
  fi
  SERVER="https://${MINIKUBE_IP}:8443"
elif [[ "${CLUSTER_TYPE}" == "kind" ]]; then
  SERVER="https://$(kubectl --context="${CONTEXT_NAME}" get nodes -o jsonpath="{.items[0].status.addresses[?(@.type=='InternalIP')].address}"):6443"
else
  echo "Unsupported cluster type: ${CLUSTER_TYPE}"
  exit 1
fi

# クライアント証明書、キー、CA証明書のパスまたはデータを取得
CA_DATA=$(kubectl --context="${CONTEXT_NAME}" config view --raw -o jsonpath="{.clusters[?(@.name == '${CONTEXT_NAME}')].cluster.certificate-authority-data}")
if [ -z "${CA_DATA}" ]; then
  CA_PATH=$(kubectl --context="${CONTEXT_NAME}" config view -o jsonpath="{.clusters[?(@.name == '${CONTEXT_NAME}')].cluster.certificate-authority}")
  if [ ! -f "${CA_PATH}" ]; then
    echo "Certification Authority file does not exist" >&2
    exit 1
  fi
  CA_DATA=$(cat ${CA_PATH} | base64 | tr -d '\n')
fi

CLIENT_CERT_DATA=$(kubectl --context="${CONTEXT_NAME}" config view --raw -o jsonpath="{.users[?(@.name == '${CONTEXT_NAME}')].user.client-certificate-data}")
if [ -z "${CLIENT_CERT_DATA}" ]; then
  CLIENT_CERT_PATH=$(kubectl --context="${CONTEXT_NAME}" config view -o jsonpath="{.users[?(@.name == '${CONTEXT_NAME}')].user.client-certificate}")
  if [ ! -f "${CLIENT_CERT_PATH}" ]; then
    echo "Client certificate file does not exist" >&2
    exit 1
  fi
  CLIENT_CERT_DATA=$(cat "${CLIENT_CERT_PATH}" | base64 | tr -d '\n')
fi

CLIENT_KEY_DATA=$(kubectl --context="${CONTEXT_NAME}" config view --raw -o jsonpath="{.users[?(@.name == '${CONTEXT_NAME}')].user.client-key-data}")
if [ -z "${CLIENT_KEY_DATA}" ]; then
  CLIENT_KEY_PATH=$(kubectl --context="${CONTEXT_NAME}" config view -o jsonpath="{.users[?(@.name == '${CONTEXT_NAME}')].user.client-key}")
  if [ ! -f "${CLIENT_KEY_PATH}" ]; then
    echo "Client key file does not exist" >&2
    exit 1
  fi
  CLIENT_KEY_DATA=$(cat "${CLIENT_KEY_PATH}" | base64 | tr -d '\n')
fi

# シークレットを生成
cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
  labels:
    argocd.argoproj.io/secret-type: cluster
type: Opaque
stringData:
  name: ${CONTEXT_NAME}
  server: ${SERVER}
  config: |
    {
      "tlsClientConfig": {
        "insecure": false,
        "caData": "${CA_DATA}",
        "certData": "${CLIENT_CERT_DATA}",
        "keyData": "${CLIENT_KEY_DATA}"
      }
    }
EOF


#!/usr/bin/env bash

# エラーが発生した場合はスクリプトを停止
set -e

# ヘルプメッセージの表示
function print_help() {
  echo "Usage: $0 <secret-name> [-r|--region <region>] [-p|--profile <profile>] [-n|--namespace <namespace>]"
  echo
  echo "Arguments:"
  echo "  secret-name      Kubernetes secret name (required)"
  echo
  echo "Options:"
  echo "  -r, --region     AWS region (default: ap-northeast-1 or environment value)"
  echo "  -p, --profile    AWS profile (default: default or environment value)"
  echo "  -n, --namespace  Kubernetes namespace (default: default)"
  echo "  -h, --help       Show this help message"
  echo
  echo "Examples:"
  echo "  $0 ecr-token"
  echo "      Generate a Kubernetes secret named 'ecr-token' in the default namespace."
  echo
  echo "  $0 ecr-token -n webapp -r us-west-2 -p my-profile"
  echo "      Generate a Kubernetes secret named 'ecr-token' in the 'webapp' namespace,"
  echo "      using the AWS region 'us-west-2' and the profile 'my-profile'."
}

# ヘルプオプションを最初にチェック
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  print_help
  exit 0
fi

# 必須引数チェック
if [[ $# -lt 1 ]]; then
  echo "Error: Secret name is required."
  print_help
  exit 1
fi

# 必須引数
SECRET_NAME=$1
shift # 引数を次にシフト

# デフォルト値の設定
AWS_REGION=${AWS_REGION:-"ap-northeast-1"} # AWS リージョン（デフォルト: ap-northeast-1）
AWS_PROFILE=${AWS_PROFILE:-"default"}      # AWS プロファイル（デフォルト: default）
NAMESPACE="default"                        # デフォルト namespace は "default"

# オプションのパース
while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--region)
      AWS_REGION="$2"
      shift 2
      ;;
    -p|--profile)
      AWS_PROFILE="$2"
      shift 2
      ;;
    -n|--namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    -h|--help)
      print_help
      exit 0
      ;;
    -*)
      echo "Error: Unknown option: $1"
      print_help
      exit 1
      ;;
    *)
      echo "Error: Unknown positional argument: $1"
      print_help
      exit 1
      ;;
  esac
done

# AWS アカウント ID を取得
AWS_ACCOUNT_ID=$(AWS_PROFILE=${AWS_PROFILE} aws sts get-caller-identity --query "Account" --output text)
if [ -z "${AWS_ACCOUNT_ID}" ]; then
  echo "Failed to retrieve AWS account ID."
  exit 1
fi

# ECR ホストを生成
ECR_HOST="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

# AWS ECR パスワードを取得
ECR_PASSWORD=$(AWS_PROFILE=${AWS_PROFILE} aws ecr get-login-password --region ${AWS_REGION})

# .dockerconfigjson の構造を生成
DOCKER_CONFIG_JSON=$(cat <<EOF
{
  "auths": {
    "${ECR_HOST}": {
      "username": "AWS",
      "password": "${ECR_PASSWORD}",
      "auth": "$(echo -n "AWS:${ECR_PASSWORD}" | base64 -w 0)"
    }
  }
}
EOF
)

# YAML を出力
cat <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
data:
  .dockerconfigjson: $(echo -n "${DOCKER_CONFIG_JSON}" | base64 -w 0)
type: kubernetes.io/dockerconfigjson
EOF

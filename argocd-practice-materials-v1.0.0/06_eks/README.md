# AWS EKS で ArgoCD を動かしてみよう

- [webapp-cluster](./webapp-cluster/)
  - sample-webapp-php などのアプリを動かすためのクラスターに必要な設定ファイルを置いているディレクトリです
  - ArgoCD のデプロイ先として指定されます
- [argocd-cluster](./argocdp-cluster/)
  - ArgoCD を動かすクラスターに必要な設定ファイルを置いているディレクトリです
- [terraforms](./terraforms)
  - AWS リソースを作成するための terraform ファイルを置いているディレクトリです
  - app-cluster や argocd-cluster を動かすための VPC 環境や、app-cluster のための RDS や SecurityGroup を作成します

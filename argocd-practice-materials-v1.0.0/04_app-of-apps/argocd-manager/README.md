# ArogCD Application 管理

このディレクトリ以下の manifests は ArgoCD の Application をデプロイするための Application を管理してます。  
つまり、アプリケーションのためのアプリ（App of Apps）です。

## App of Apps 
```sh
cd /path/to/argocd-manager
```

```sh
kubectl apply -k ./manifests
```

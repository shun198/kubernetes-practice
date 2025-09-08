# App of Apps パターン
## 構成
- [ArogCD の管理](./argocd-manager)
  - ArgoCD 自体の管理を行う役割です
  - ArgoCD をインストールしたい K8sクラスターへ直接 manifest を apply します
- [ArgoCD Application 管理](./example-argocd-apps)
  - ArgoCD を使ってデプロイするための ArgoCD 用リソースを管理します
  - ArgoCD の マスターアプリケーションによって適用されます（そのため直接コマンドで `kubectl apply` する必要がありません）
  - デプロイしたいアプリケーションが増えたら、こちらに Application の manifest を追加します


## 注意
本資料の中でディレクトリ名で prod など本番環境を彷彿する名前を使っているところがありますが、そのまま本番で運用しないでください。  
本番環境で利用するにはセキュリティや可用性の観点で不備があります（権限管理、secretの管理、HighAvailabirity構成にしてないなど）。  
あくまでも参考資料としてご活用ください。


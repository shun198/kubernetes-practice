# ArgoCD の構成を manifest で定義して管理する
## apply
```sh
cd /path/to/03_declarative-apps
```
※ `/path/to/` の部分は環境に合わせて適宜変えてください。

### dev
```sh
kubectl apply -k ./manifests/overlays/dev
```

### prod
```sh
kubectl apply -k ./manifests/overlays/dev
```

## 注意
本資料の中でディレクトリ名で prod など本番環境を彷彿する名前を使っているところがありますが、そのまま本番で運用しないでください。  
本番環境で利用するにはセキュリティや可用性の観点で不備があります（権限管理、secretの管理、HighAvailabirity構成にしてないなど）。  
あくまでも参考資料としてご活用ください。


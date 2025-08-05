# Apply ReplicaSet

- ReplicaSet can be applied by the following command

```
kubectl apply -f ./manifests/webserver-replicaset.yaml
```

# ClusterIP Service

- Create ClusterIP Service by the following command

```
kubectl create service clusterip webserver-service -n webapp --tcp=80:80 --dry-run=client --output yaml > ./manifests/cluster-ip/webserver-service.yaml
```

- Apply ClusterIP Service

```
kubectl apply -f ./manifests/cluster-ip/webserver-service.yaml
```

- Access Pod via ClusterIP Service

```
kubectl -n webapp run curl-pod --restart=Never -it --rm --image=curlimages/curl:latest -- curl --head http://webserver-service
```

```HTTP/1.1 200 OK
Server: nginx/1.29.0
Date: Tue, 05 Aug 2025 05:06:42 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 24 Jun 2025 17:22:41 GMT
Connection: keep-alive
ETag: "685adee1-267"
Accept-Ranges: bytes

pod "curl-pod" deleted
```

# Node Pod Service

- Create Node Pod Service by the following command

```
kubectl apply -f ./manifests/node/webserver-service.yaml
```

- Confirm pods and services

```
kubectl -n webapp get all --output wide
NAME                             READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
pod/webserver-replicaset-6b54h   1/1     Running   0          49m   10.244.0.16   minikube   <none>           <none>
pod/webserver-replicaset-bjtmd   1/1     Running   0          49m   10.244.0.17   minikube   <none>           <none>
pod/webserver-replicaset-zsd5t   1/1     Running   0          49m   10.244.0.18   minikube   <none>           <none>

NAME                        TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE   SELECTOR
service/webserver-service   NodePort   10.99.80.249   <none>        80:30000/TCP   17m   app=webserver

NAME                                   DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES         SELECTOR
replicaset.apps/webserver-replicaset   3         3         3       49m   webserver    nginx:latest   app=webserver
```

- Execute the following command to check node ip

```
kubectl -n webapp get node --output wide
```

- Use minikube ssh to request to node

```
kubectl -n webapp get node --output wide
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
minikube   Ready    control-plane   2d    v1.30.0   192.168.49.2   <none>        Ubuntu 22.04.5 LTS   6.10.14-linuxkit   docker://28.1.1
docker@minikube:~$ curl --head http://192.168.49.2:30000
HTTP/1.1 200 OK
Server: nginx/1.29.0
Date: Tue, 05 Aug 2025 05:27:51 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 24 Jun 2025 17:22:41 GMT
Connection: keep-alive
ETag: "685adee1-267"
Accept-Ranges: bytes

docker@minikube:~$
```

# Load Balancer Service

- Create Load Balancer Service by the following command

```
kubectl apply -f ./manifests/load-balancer/webserver-service.yaml
```

- Use minikube tunnel and confirm Load Balancer Service

```
minikube tunnel
✅  トンネルが無事開始しました

📌  注意: トンネルにアクセスするにはこのプロセスが存続しなければならないため、このターミナルはクローズしないでください ...

❗  webserver-service service/ingress は次の公開用特権ポートを要求します:  [80]
🔑  sudo permission will be asked for it.
🏃  webserver-service サービス用のトンネルを起動しています。
Password:
```

```
kubectl get svc -n webapp webserver-service -w
NAME                TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
webserver-service   LoadBalancer   10.99.80.249   127.0.0.1     80:30000/TCP   48m
```

- curl to 127.0.0.1

```
curl --head http://127.0.0.1
HTTP/1.1 200 OK
Server: nginx/1.29.0
Date: Tue, 05 Aug 2025 05:54:50 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 24 Jun 2025 17:22:41 GMT
Connection: keep-alive
ETag: "685adee1-267"
Accept-Ranges: bytes
```

# ExternalName Service

- Create ExternalName Service by the following command

```
kubectl apply -f ./manifests/external-name/external-name-service.yaml
```

- Confirm my-external-service is created

```
kubectl -n webapp get svc --output wide
NAME                  TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE   SELECTOR
my-external-service   ExternalName   <none>         example.com   <none>         8s    <none>
```

- nslookup service

```
kubectl -n webapp run busybox-pod --restart=Never -it --rm --image=busybox:latest -- nslookup my-external-service
Server:         10.96.0.10
Address:        10.96.0.10:53

** server can't find my-external-service.cluster.local: NXDOMAIN

** server can't find my-external-service.cluster.local: NXDOMAIN

** server can't find my-external-service.svc.cluster.local: NXDOMAIN

** server can't find my-external-service.svc.cluster.local: NXDOMAIN

my-external-service.webapp.svc.cluster.local    canonical name = example.com
Name:   example.com
Address: 2600:1406:bc00:53::b81e:94ce
Name:   example.com
Address: 2600:1408:ec00:36::1736:7f31
Name:   example.com
Address: 2600:1408:ec00:36::1736:7f24
Name:   example.com
Address: 2600:1406:bc00:53::b81e:94c8
Name:   example.com
Address: 2600:1406:3a00:21::173e:2e66
Name:   example.com
Address: 2600:1406:3a00:21::173e:2e65

my-external-service.webapp.svc.cluster.local    canonical name = example.com
Name:   example.com
Address: 23.215.0.136
Name:   example.com
Address: 23.192.228.80
Name:   example.com
Address: 23.192.228.84
Name:   example.com
Address: 23.215.0.138
Name:   example.com
Address: 96.7.128.198
Name:   example.com
Address: 96.7.128.175

pod "busybox-pod" deleted
pod webapp/busybox-pod terminated (Error)
```

```
nslookup example.com
Server:         2404:7a84:50c0:5a00:569b:49ff:febb:b08c
Address:        2404:7a84:50c0:5a00:569b:49ff:febb:b08c#53

Non-authoritative answer:
Name:   example.com
Address: 23.192.228.80
Name:   example.com
Address: 23.192.228.84
Name:   example.com
Address: 23.215.0.136
Name:   example.com
Address: 23.215.0.138
Name:   example.com
Address: 96.7.128.175
Name:   example.com
Address: 96.7.128.198
```

# Delete Services

```
kubectl delete -f ./manifests/cluster-ip/webserver-service.yaml
service "webserver-service" deleted
kubectl delete -f ./manifests/node/webserver-service.yaml
service "webserver-service" deleted
kubectl delete -f ./manifests/load-balancer/webserver-service.yaml
service "webserver-service" deleted
kubectl delete -f ./manifests/external-name/external-name-service.yaml
service "my-external-service" deleted
```

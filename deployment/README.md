- Apply deployment to cluster

```
kubectl apply -f ./manifests/webserver-deployment.yaml
```

- Confirm deployment

```
kubectl -n webapp get all
NAME                                        READY   STATUS    RESTARTS   AGE
pod/webserver-deployment-5cd4b9b767-4gkdq   1/1     Running   0          9m10s
pod/webserver-deployment-5cd4b9b767-ctlzw   1/1     Running   0          9m10s
pod/webserver-deployment-5cd4b9b767-rxl8k   1/1     Running   0          9m10s

NAME                                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/webserver-deployment   3/3     3            3           9m10s

NAME                                              DESIRED   CURRENT   READY   AGE
replicaset.apps/webserver-deployment-5cd4b9b767   3         3         3       9m10s
```

- Scale pods

```
kubectl -n webapp scale deployment webserver-deployment --replicas=5
NAME                                        READY   STATUS    RESTARTS   AGE
pod/webserver-deployment-5cd4b9b767-4gkdq   1/1     Running   0          10m
pod/webserver-deployment-5cd4b9b767-ctlzw   1/1     Running   0          10m
pod/webserver-deployment-5cd4b9b767-kqjbh   1/1     Running   0          15s
pod/webserver-deployment-5cd4b9b767-q6h5m   1/1     Running   0          15s
pod/webserver-deployment-5cd4b9b767-rxl8k   1/1     Running   0          10m

NAME                                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/webserver-deployment   5/5     5            5           10m

NAME                                              DESIRED   CURRENT   READY   AGE
replicaset.apps/webserver-deployment-5cd4b9b767   5         5         5       10m
```

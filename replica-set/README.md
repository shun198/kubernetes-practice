- ReplicaSet can be applied by the following command

```
kubectl apply -f ./manifests/webserver-replicaset.yaml
```

- ReplicaSet can be displayed by the following command

```
kubectl get replicaset -n webapp
```

- Pods inside ReplicaSet can be displayed by the following command

```
kubectl get all -n webapp
```

- The number of pods can be changed by the following command

```
kubectl -n webapp scale replicaset webserver-replicaset --replicas=2
```

- ReplicaSet manifests can be edited by the following command (Not for production)

```
kubectl -n webapp edit replicaset webserver-replicaset
```

- Changes inside webserver-replicaset.yaml can be applied by the following command

```
kubectl apply -f ./manifests/webserver-replicaset.yaml
```

- pods can be monitored by the following command

```
kubectl get pod -n webapp --watch
NAME                         READY   STATUS    RESTARTS   AGE
webserver-replicaset-2hh5q   1/1     Running   0          7m22s
webserver-replicaset-5fctq   1/1     Running   0          7m22s
```

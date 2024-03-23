# multicluster api server

## start three minikube

```
minikube start --bootstrapper=kubeadm --memory 4096 --cpus 4 --profile cluster1
minikube start --bootstrapper=kubeadm --memory 4096 --cpus 4 --profile cluster2
minikube start --bootstrapper=kubeadm --memory 4096 --cpus 4 --profile cluster3
```

## enable persistent volumes

```
for cluster in cluster1 cluster2 cluster3; do
  minikube --profile ${cluster} addons enable volumesnapshots
  minikube --profile ${cluster} addons enable csi-hostpath-driver
  minikube --profile ${cluster} addons disable storage-provisioner
  minikube --profile ${cluster} addons disable default-storageclass
  kubectl --context ${cluster} patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
done
```

## deploy/configure cert manager

```
for cluster in cluster1 cluster2 cluster3; do
  kubectl --context ${cluster} apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
  kubectl --context ${cluster} apply -f ./issuer.yaml -n cert-manager
done
```

```
for cluster in cluster1 cluster2 cluster3; do
  kubectl --context ${cluster} create namespace h2
  kubectl --context ${cluster} apply -f ./etcd-deployment.yaml -n h2
  kubectl --context ${cluster} apply -f ./api-server-deployment.yaml -n h2
  kubectl --context ${cluster} apply -f ./apiservice.yaml
done
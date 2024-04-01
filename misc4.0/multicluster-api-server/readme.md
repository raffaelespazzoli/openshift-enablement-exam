# multicluster api server

## start three minikube

```
minikube start --bootstrapper=kubeadm --memory 4096 --cpus 4 --cni cilium --subnet 192.168.49.0/24 --service-cluster-ip-range 10.96.0.0/24 --profile cluster1
minikube start --bootstrapper=kubeadm --memory 4096 --cpus 4 --cni cilium --subnet 192.168.50.0/24 --service-cluster-ip-range 10.96.1.0/24 --profile cluster2
minikube start --bootstrapper=kubeadm --memory 4096 --cpus 4 --cni cilium --subnet 192.168.51.0/24 --service-cluster-ip-range 10.96.2.0/24 --profile cluster3
```

## enable persistent volumes

```
for cluster in cluster1 cluster2 cluster3; do
  minikube --profile ${cluster} addons enable dashboard
  minikube --profile ${cluster} addons enable volumesnapshots
  minikube --profile ${cluster} addons enable csi-hostpath-driver
  minikube --profile ${cluster} addons disable storage-provisioner
  minikube --profile ${cluster} addons disable default-storageclass
  kubectl --context ${cluster} patch storageclass csi-hostpath-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
done
```

## enable cluster mesh

```
for cluster in cluster1 cluster2 cluster3; do
  cilium clustermesh enable --context ${cluster} --service-type NodePort
done
```

## open the dashboard

  minikube --profile ${cluster} dashboard --url true

## deploy/configure cert manager

```
for cluster in cluster1 cluster2 cluster3; do
  kubectl --context ${cluster} apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
  kubectl --context ${cluster} apply -f ./issuer.yaml -n cert-manager
done
```

## deploy h2 apiserver

```
ssh-keygen -m pem -b 4096 -t rsa -f sa.key.pem -N '' -C "key for sa"
openssl rsa -in sa.key.pem -pubout -out sa.key.pub.pem


for cluster in cluster1 cluster2 cluster3; do
  kubectl --context ${cluster} create namespace h2
  kubectl --context ${cluster} create secret generic sa-key --from-file=sa.pub=sa.key.pub.pem --from-file=sa.key=sa.key.pem -n h2
  kubectl --context ${cluster} apply -f ./etcd-deployment.yaml -n h2
  kubectl --context ${cluster} apply -f ./api-server-deployment.yaml -n h2
  kubectl --context ${cluster} apply -f ./apiservice.yaml
done
```

## remove everything

for cluster in cluster1 cluster2 cluster3; do
  minikube delete --profile ${cluster}
done
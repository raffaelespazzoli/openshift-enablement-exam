

## setup helm

```sh
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo add cilium https://helm.cilium.io/
```

## deploy kind clusters

```sh
sudo su #cilium does not work with rootless containers
setenforce 0
kind create cluster -n cluster1 --config ./kind-config/config-cluster1.yaml
kind create cluster -n cluster2 --config ./kind-config/config-cluster2.yaml
kind create cluster -n cluster3 --config ./kind-config/config-cluster3.yaml
```

## deploy cert-manager

```sh
for cluster in cluster1 cluster2 cluster3; do
  kubectl --context kind-${cluster} apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
done
```

## install cilium -- step 1

```sh
for cluster in cluster1 cluster2 cluster3; do
  cluster=${cluster} ordinal=${cluster: -1} envsubst < ./cilium/values1.yaml > /tmp/${cluster}-values.yaml
  helm --kube-context kind-${cluster} upgrade -i cilium cilium/cilium --version "1.16.0-pre.0" --namespace kube-system -f /tmp/${cluster}-values.yaml
done
```  

wait for all the pods to be up

```sh
watch kubectl --context kind-cluster1 get pods -A
```

## deploy cert-manager

this sort of hack is to share the CA across clusters

```sh
kubectl --context kind-cluster1 apply -f ./cert-manager/issuer-cluster1.yaml -n cert-manager
kubectl --context kind-cluster1 get secret root-secret -n cert-manager -o yaml > /tmp/root-secret.yaml
```


```sh
for cluster in cluster2 cluster3; do
  kubectl --context kind-${cluster} apply -f /tmp/root-secret.yaml
  kubectl --context kind-${cluster} apply -f ./cert-manager/issuer-others.yaml -n cert-manager
done
```

## deploy lb configuration

inspect kind network

```sh
podman network inspect -f '{{range .Subnets}}{{if eq (len .Subnet.IP) 4}}{{.Subnet}}{{end}}{{end}}' kind
10.89.0.0/24
```

carve three non overlapping subnets out of that CIDR starting from the end for the three clusters. /29 would give us 8 IPs , which is plenty, in this case.

```sh
export cidr_cluster1="10.89.0.224/29"
export cidr_cluster2="10.89.0.232/29"
export cidr_cluster3="10.89.0.240/29"
```

```sh
for cluster in cluster1 cluster2 cluster3; do
  vcidr=cidr_${cluster}
  cidr=${!vcidr} envsubst < ./cilium/ippool.yaml | kubectl --context kind-${cluster} apply -f -
done
```

## install cilium step2

```sh
declare -A cluster_ips
export cluster1_ip="10.89.0.224"
export cluster2_ip="10.89.0.232"
export cluster3_ip="10.89.0.240"
cluster_ips["cluster1"]="10.89.0.224"
cluster_ips["cluster2"]="10.89.0.232"
cluster_ips["cluster3"]="10.89.0.240"
for cluster in cluster1 cluster2 cluster3; do
  cluster=${cluster} ordinal=${cluster: -1} apiserver_ip=${cluster_ips[${cluster}]}  envsubst < ./cilium/values2.yaml > /tmp/${cluster}-values.yaml
  helm --kube-context kind-${cluster} upgrade -i cilium cilium/cilium --version "1.16.0-pre.0" --namespace kube-system -f /tmp/${cluster}-values.yaml
done
```   

verify that clusters are successfully connected:

```sh
cilium status --context kind-cluster1
cilium status --context kind-cluster2
cilium status --context kind-cluster3
cilium clustermesh status --context kind-cluster1
cilium clustermesh status --context kind-cluster2
cilium clustermesh status --context kind-cluster3
```

## Install prometheus and grafana (optional)

```sh
for cluster in cluster1 cluster2 cluster3; do
  kubectl --context kind-${cluster} apply -f https://raw.githubusercontent.com/cilium/cilium/1.16.0-pre.0/examples/kubernetes/addons/prometheus/monitoring-example.yaml
done
```

access grafana

```sh
kubectl --context kind-${cluster} -n cilium-monitoring port-forward service/grafana --address 0.0.0.0 --address :: 3000:3000
```

access hubble ui

```sh
cilium --context kind-${cluster} hubble ui
```

## deploy dashboard (optional)

```sh
for cluster in cluster1 cluster2 cluster3; do
  #kubectl --context kind-${cluster} apply -f https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/master/deploy/single/all-in-one-dbless.yaml
  #kubectl --context kind-${cluster} patch deployment -n kong proxy-kong -p '{"spec":{"replicas":1,"template":{"spec":{"containers":[{"name":"proxy","ports":[{"containerPort":8e3,"hostPort":80,"name":"proxy-tcp","protocol":"TCP"},{"containerPort":8443,"hostPort":443,"name":"proxy-ssl","protocol":"TCP"}]}],"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/control-plane","operator":"Equal","effect":"NoSchedule"},{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}'
  #kubectl --context kind-${cluster} patch service -n kong kong-proxy -p '{"spec":{"type":"NodePort"}}'
  helm --kube-context kind-${cluster} upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
done
```

### uninstall cilium 
```sh
for cluster in cluster1 cluster2 cluster3; do
helm --kube-context kind-${cluster} uninstall cilium --namespace kube-system
done
``` 

## remove everything

```sh
kind delete cluster -n cluster1
kind delete cluster -n cluster2
kind delete cluster -n cluster3
```

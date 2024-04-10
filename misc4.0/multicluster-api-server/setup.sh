# define needed helm charts

helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo add cilium https://helm.cilium.io/
helm repo add yugabytedb https://charts.yugabyte.com
helm repo add bitnami https://charts.bitnami.com/bitnami

# create kind clusters

setenforce 0
kind create cluster -n cluster1 --config ./kind-config/config-cluster1.yaml & 
kind create cluster -n cluster2 --config ./kind-config/config-cluster2.yaml &
kind create cluster -n cluster3 --config ./kind-config/config-cluster3.yaml &
wait

# deploy cert-manager

for cluster in cluster1 cluster2 cluster3; do
  kubectl --context kind-${cluster} apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.4/cert-manager.yaml
done

# install cilium -- step 1

for cluster in cluster1 cluster2 cluster3; do
  cluster=${cluster} ordinal=${cluster: -1} envsubst < ./cilium/values1.yaml > /tmp/${cluster}-values.yaml
  helm --kube-context kind-${cluster} upgrade -i cilium cilium/cilium --version "1.16.0-pre.0" --namespace kube-system -f /tmp/${cluster}-values.yaml 
done

# wait for all the pods to be up

kubectl --context kind-cluster1 wait pod --all --for=condition=Ready -A --timeout=600s & 
kubectl --context kind-cluster2 wait pod --all --for=condition=Ready -A --timeout=600s & 
kubectl --context kind-cluster3 wait pod --all --for=condition=Ready -A --timeout=600s &
wait

# deploy cert manager issuer

kubectl --context kind-cluster1 apply -f ./cert-manager/issuer-cluster1.yaml -n cert-manager
sleep 1
kubectl --context kind-cluster1 get secret root-secret -n cert-manager -o yaml > /tmp/root-secret.yaml

for cluster in cluster2 cluster3; do
  kubectl --context kind-${cluster} apply -f /tmp/root-secret.yaml
  kubectl --context kind-${cluster} apply -f ./cert-manager/issuer-others.yaml -n cert-manager
done

# deploy lb configuration

export cidr_cluster1="10.89.0.224/29"
export cidr_cluster2="10.89.0.232/29"
export cidr_cluster3="10.89.0.240/29"
for cluster in cluster1 cluster2 cluster3; do
  vcidr=cidr_${cluster}
  cidr=${!vcidr} envsubst < ./cilium/ippool.yaml | kubectl --context kind-${cluster} apply -f -
done

# install cilium step 2

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

# configure coredns for statefulsets

export cluster1_coredns_ip="10.89.0.225"
export cluster2_coredns_ip="10.89.0.233"
export cluster3_coredns_ip="10.89.0.241"
declare -A coredns_ips
coredns_ips["cluster1"]="10.89.0.225"
coredns_ips["cluster2"]="10.89.0.233"
coredns_ips["cluster3"]="10.89.0.241"
for cluster in cluster1 cluster2 cluster3; do
  kubectl --context kind-${cluster} patch deployment coredns -n kube-system -p '{"spec":{"replicas": 1,"template":{"spec":{"containers": [{"name":"coredns","image":"quay.io/raffaelespazzoli/coredns:arm64-gathersrv-root", "imagePullPolicy": "Always", "resources": {"limits":{"memory":"512Mi"}}}]}}}}'
  envsubst < ./core-dns/corefile-configmap-${cluster}.yaml | kubectl --context kind-${cluster} apply -f -
  coredns_ip=${coredns_ips[${cluster}]} envsubst < ./core-dns/coredns-service.yaml | kubectl --context kind-${cluster} apply -f -
done

# deploy ingress gateway

declare -A ingress_ips
ingress_ips["cluster1"]="10.89.0.226"
ingress_ips["cluster2"]="10.89.0.234"
ingress_ips["cluster3"]="10.89.0.242"
for cluster in cluster1 cluster2 cluster3; do
  ingress_ip=${ingress_ips[${cluster}]}  envsubst < ./contour/values.yaml > /tmp/values.yaml
  helm --kube-context kind-${cluster} upgrade -i contour bitnami/contour --namespace projectcontour --create-namespace -f /tmp/values.yaml
done

# deploy dashboard
for cluster in cluster1 cluster2 cluster3; do
  cluster=${cluster}  envsubst < ./dashboard/values.yaml > /tmp/values.yaml
  helm --kube-context kind-${cluster} upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard -f /tmp/values.yaml
  cluster=${cluster}  envsubst < ./dashboard/httpproxy.yaml | kubectl --context kind-${cluster} apply -f -
done

# create h2 namespace

for cluster in cluster1 cluster2 cluster3; do
  kubectl --context kind-${cluster} create namespace h2
done

# deploy kcp

declare -A kcp_ips
kcp_ips["cluster1"]="10.89.0.227"
kcp_ips["cluster2"]="10.89.0.235"
kcp_ips["cluster3"]="10.89.0.243"
for cluster in cluster1 cluster2 cluster3; do
  cluster=${cluster} envsubst < ./shared-etcd/etcd-deployment.yaml | kubectl --context kind-${cluster} apply -f - -n h2
  kcp_ip=${kcp_ips[${cluster}]} cluster=${cluster}  envsubst < ./kcp/values.yaml > /tmp/values.yaml
  helm --kube-context kind-${cluster} upgrade -i kcp ./kcp/charts/kcp -n h2 -f /tmp/values.yaml
done 


# wait for all pods to be up

kubectl --context kind-cluster1 wait pod --all --for=condition=Ready -A --timeout=600s & 
kubectl --context kind-cluster2 wait pod --all --for=condition=Ready -A --timeout=600s & 
kubectl --context kind-cluster3 wait pod --all --for=condition=Ready -A --timeout=600s &
wait
  
# Install all in one
```
oc new-project prometheus
oc create configmap grafana --from-file=grafana.ini
oc create configmap prometheus --from-file=prometheus.yaml
oc process -f all-in-one.yaml -p NAMESPACE=prometheus | oc apply -f -
oc adm policy add-cluster-role-to-user cluster-reader -z prometheus
```

# Install Prometheus

```
oc new-project prometheus
oc process -f https://raw.githubusercontent.com/minishift/minishift-addons/master/add-ons/prometheus/prometheus.yaml -p NAMESPACE=prometheus | oc apply -f -
oc delete configmap prometheus
oc create configmap prometheus --from-file=prometheus.yml=prometheus-kubernetes.yaml
oc rollout latest deployment/prometheus
```
move oauth proxy to graphana


# Install kube-state-metrics
```
oc process -f kubernetes/kube-state-metrics-template.yaml -p NAMESPACE=prometheus | oc apply -f -
oc adm policy add-cluster-role-to-user cluster-reader -z kube-state-metrics
```

#install Grafana
```
oc process -f https://raw.githubusercontent.com/wkulhanek/docker-openshift-grafana/master/grafana.yaml -p NAMESPACE=prometheus | oc apply -f -
```
add oauth proxy



relevant projects:
https://github.com/wkulhanek/OpenShift-Prometheus
https://github.com/kubernetes/kube-state-metrics
https://github.com/minishift/minishift-addons/tree/master/add-ons/prometheus
https://github.com/coreos/prometheus-operator
https://github.com/prometheus/prometheus/tree/master/documentation/examples
https://github.com/openshift/oauth-proxy

# useful metrics

sum(kube_pod_container_resource_requests_memory_bytes)
sum(kube_node_status_allocatable_memory_bytes)
sum(container_memory_usage_bytes)
sum(kube_pod_container_resource_limits_memory_bytes)

sum (kube_pod_container_resource_requests_cpu_cores)
sum(kube_node_status_allocatable_cpu_bytes)
sum (rate (container_cpu_usage_seconds_total {container_name=~".+", container_name!="POD"} [5m])) by (container_name)
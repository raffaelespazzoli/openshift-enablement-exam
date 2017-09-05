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
fix namespace

#install Grafana
```
oc process -f https://raw.githubusercontent.com/wkulhanek/docker-openshift-grafana/master/grafana.yaml -p NAMESPACE=prometheus | oc apply -f -
```
add oauth proxy



relevant projects:
https://github.com/kubernetes/kube-state-metrics
https://github.com/minishift/minishift-addons/tree/master/add-ons/prometheus
https://github.com/coreos/prometheus-operator
https://github.com/prometheus/prometheus/tree/master/documentation/examples
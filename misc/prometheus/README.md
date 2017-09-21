# Install all in one
This will install promethues, grafana and the additional kube-metrics prometheus scraper
```
oc new-project prometheus
oc create sa prometheus
oc adm policy add-cluster-role-to-user cluster-reader -z prometheus
oc create configmap grafana --from-file=grafana.ini
oc create configmap prometheus --from-file=prometheus.yaml
oc process -f all-in-one.yaml -p NAMESPACE=prometheus | oc apply -f -

```

# Configure Grafana
Unfortunately I couldn't find a simple way to automate the following steps

## configure the Prometheus datasource

* Log into Grafana using the Route provided in the Template and using default account `admin` with password `admin` (maybe it would be a good idea to change the password after this...).
* On the Home Dashboard click *Add data source*
* Use the following values for the datasource *Config*:
** Name: `prometheus`
** Type: `prometheus`
** Url: `http://prometheus:9090`
** Access: proxy
* Click `Add`
* Click `Save & Test`. You should see a message that the data source is working.

## create the dashboards

repeat the followig steps for each of the dashboard in the `dashboards` directory
* In Grafana select the Icon on the top left and then select `Dashboards / Import`.
* Either copy/paste the contents of the JSON File (make sure to keep the correct formatting) or click the `Upload .json File` button selecting the .json file.
* In the next dialog enter `OpenShift` as the name and select the previously created datasource `prometheus` for *Prometheus*.
* Click *Import*




# Notes....

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

memory estimation
sum(sum(kube_pod_container_resource_requests_memory_bytes) by (node) * on (node) abs(kube_node_spec_unschedulable -1) )
sum(sum(kube_pod_container_resource_requests_memory_bytes) by (node) * on (node) abs(kube_node_spec_unschedulable -1))*1.2
sum(sum(kube_pod_container_resource_requests_memory_bytes) by (node) * on (node) abs(kube_node_spec_unschedulable -1))*0.8
sum(container_memory_usage_bytes{container_name=~".+", container_name!="POD"})

memory sizing
sum(sum(kube_pod_container_resource_requests_memory_bytes) by (node) * on (node) abs(kube_node_spec_unschedulable -1))
sum(sum(kube_node_status_allocatable_memory_bytes) by (node) * on (node) abs(kube_node_spec_unschedulable -1))
sum(sum(kube_node_status_allocatable_memory_bytes) by (node) * on (node) abs(kube_node_spec_unschedulable -1))*0.8
sum(sum(kube_node_status_allocatable_memory_bytes) by (node) * on (node) abs(kube_node_spec_unschedulable -1))*0.4

cpu estimation
sum (sum (kube_pod_container_resource_requests_cpu_cores) by (node) * on (node) abs(kube_node_spec_unschedulable -1) )
sum (sum (kube_pod_container_resource_requests_cpu_cores) by (node) * on (node) abs(kube_node_spec_unschedulable -1) )*1.2
sum (sum (kube_pod_container_resource_requests_cpu_cores) by (node) * on (node) abs(kube_node_spec_unschedulable -1) )*0.8
sum (rate (container_cpu_usage_seconds_total {container_name=~".+", container_name!="POD"} [5m]))

cpu sizing


sum(kube_pod_container_resource_requests_memory_bytes)
sum(kube_node_status_allocatable_memory_bytes)
sum(container_memory_usage_bytes)
sum(kube_pod_container_resource_limits_memory_bytes)

sum (kube_pod_container_resource_requests_cpu_cores)
sum(kube_node_status_allocatable_cpu_bytes)
sum (rate (container_cpu_usage_seconds_total {container_name=~".+", container_name!="POD"} [5m])) by (container_name)
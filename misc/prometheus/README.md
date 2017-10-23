# Install all in one
This will install Prometheus, Grafana and the additional kube-metrics prometheus scraper
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

## Configure the Prometheus Datasource

* Log into Grafana using the Route provided in the Template and using default account `admin` with password `admin` (maybe it would be a good idea to change the password after this...).
* On the Home Dashboard click *Add data source*
* Use the following values for the datasource *Config*:
** Name: `prometheus`
** Type: `prometheus`
** Url: `http://prometheus:9090`
** Access: proxy
* Click `Add`
* Click `Save & Test`. You should see a message that the data source is working.

## Create the Dashboards

Repeat the following steps for each of the dashboard in the `dashboards` directory: `OpenShiftCapacityDashboard.json` and `NodeOvercommittment.json`
* In Grafana select the Icon on the top left and then select `Dashboards / Import`.
* Either copy/paste the contents of the JSON File (make sure to keep the correct formatting) or click the `Upload .json File` button selecting the .json file.
* In the next dialog enter `OpenShift` as the name and select the previously created datasource `prometheus` for *Prometheus*.
* Click *Import*


# Useful PromQL Queries
Here is the list of the PromQL queries I used to generate the graphs

| Description  | Query  |
|---|---|
| Total Requested Memory (*)  | `sum(sum(kube_pod_container_resource_requests_memory_bytes) by (node) * on (node) abs(kube_node_spec_unschedulable -1) )`  |
| Total Current Memory used (**) | `sum(container_memory_usage_bytes{container_name=~".+", container_name!="POD"})`  |
| Total Allocatable Memory (*) | `sum(sum(kube_node_status_allocatable_memory_bytes) by (node) * on (node) abs(kube_node_spec_unschedulable -1))`  |
| Total Requested CPU (*)  | `sum (sum (kube_pod_container_resource_requests_cpu_cores) by (node) * on (node) abs(kube_node_spec_unschedulable -1) )`  |
| Total Current CPU Used (**) | `sum (rate (container_cpu_usage_seconds_total {container_name=~".+", container_name!="POD"} [5m]))`  |
| Total Allocatable CPU (*)  |  `sum(sum(kube_node_status_allocatable_cpu_cores) by (node) * on (node) abs(kube_node_spec_unschedulable -1) )` |
| Node Allocatable Memory, parametric by node  | `kube_node_status_allocatable_memory_bytes {node=~"$node"}`  |
| Node Requested Memory, parametric by node  | `sum(kube_pod_container_resource_requests_memory_bytes {node=~"$node"})`  |
| Node Used Memory, parametric by node  | `sum (container_memory_usage_bytes {instance=~"$node", container_name=~".+", container_name!="POD"})`  |
| Node Limit Memory, parametric by node  | `sum(kube_pod_container_resource_limits_memory_bytes {node=~"$node"})`  |
| Node Allocatable CPU, parametric by node  | `kube_node_status_allocatable_cpu_cores{node=~"$node"}`  |
| Node used CPU, parametric by node  | `sum (rate (container_cpu_usage_seconds_total {container_name=~".+", container_name!="POD", instance=~"$node"} [5m]))`  |
| Node Requested CPU, parametric by node  | `sum (kube_pod_container_resource_requests_cpu_cores{node=~"$node"})`  |
| Node Limit CPU, parametric by node  | `sum (kube_pod_container_resource_limits_cpu_cores{node=~"$node"})`  |
| Total memory quota granted | `sum (kube_resourcequota {resource="requests.memory", type="hard"})` | 
| Total cpu quota granted | `sum (kube_resourcequota {resource="requests.cpu", type="hard"})` |

(*): adjusted for non schedulable nodes

(**): I couldn't find a way to adjust it for non schedulable nodes, but it shouldn't significantly impact the metrics


# Relevant Projects:
* https://github.com/wkulhanek/OpenShift-Prometheus
* https://github.com/kubernetes/kube-state-metrics
* https://github.com/minishift/minishift-addons/tree/master/add-ons/prometheus
* https://github.com/coreos/prometheus-operator
* https://github.com/prometheus/prometheus/tree/master/documentation/examples
* https://github.com/openshift/oauth-proxy


# This will setup a monitoring stack instance

Prepare namespace

```shell
export deploy_namespace=tenant-monitoring
oc new-project ${deploy_namespace}
```

Deploy prometheus operator

```shell
envsubst < prometheus-operator.yaml | oc apply -f - -n ${deploy_namespace}
```

Deploy grafana operator

```shell
oc apply -f ./grafana-operator/crds
oc apply -f ./grafana-operator/manifests -n ${deploy_namespace}
cat ./grafana-operator/cluster_role_binding_grafana_operator.yaml | envsubst | oc apply -f -
```

Deploy stack

```shell
helm upgrade monitoring-stack ./monitoring-stack -i -n ${deploy_namespace} --create-namespace
oc create route reencrypt grafana-route --service grafana-service --port grafana-proxy -n ${deploy_namespace}
export grafana_token=$(oc sa get-token grafana-serviceaccount -n ${deploy_namespace})
envsubst < grafana-datasource-prometheus.yaml | oc apply -f - -n ${deploy_namespace}
```

Source metrics from platform prometheus (do this only if needed)

```shell
oc apply -f ./service-monitoring-platform-prometheus.yaml -n ${deploy_namespace}
```

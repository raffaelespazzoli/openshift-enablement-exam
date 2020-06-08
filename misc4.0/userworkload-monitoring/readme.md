# Deploy User workload monitoring

```shell
oc apply -f ./user-workload-monitoring-cm.yaml
```

# Deploy Oauth grafana

```shell
oc project new-multitenant-grafana
oc apply -f ./grafana.yaml -n multitenant-grafana
oc create route edge --service grafana-service grafana
```
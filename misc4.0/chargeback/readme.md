# charge-back demo

```shell
export project=chargeback-demo
export prometheus_label=team
oc new-project ${project}
oc label namespace ${project} openshift.io/cluster-monitoring='true'
envsubst < ./chargeback-rules.yaml | oc apply -f - -n ${project}
```

this is cluster dependent, add some labels to namespaces

```shell
oc label namespace amq team=team1
oc label namespace cert-manager team=team1
oc label namespace aaa-grafana-scw-v350 team=team2
oc label namespace grafana-tbox team=team2
```

Finally in a namespace watched by the grafana operator, create the dashboard:

```shell
export grafana_operator=
oc apply -f dashboard.yaml -n ${grafana_operator}
```

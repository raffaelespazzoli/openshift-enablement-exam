# Deploy network observability

## Install operator

```shell
oc apply -f ./operator.yaml -n openshift-operators
oc new-project network-observability
oc apply -f ./operator-grafana.yaml -n network-observability
```

## Install the stack

```shell
helm upgrade -i -n network-observability --atomic netobserv ./netobserv
```

enable the flow, only <4.10

```shell
GF_IP=`oc get svc flowlogs-pipeline -n network-observability -ojsonpath='{.spec.clusterIP}'` && echo $GF_IP
oc patch networks.operator.openshift.io cluster --type='json' -p "[{'op': 'add', 'path': '/spec', 'value': {'exportNetworkFlows': {'ipfix': { 'collectors': ['$GF_IP:2055']}}}}]"
```

## Enable the console plugin

only 4.10

```shell
oc patch console.operator.openshift.io cluster --type='json' -p '[{"op": "add", "path": "/spec/plugins", "value": ["network-observability-plugin"]}]'
```

## Install grafana

```shell
helm upgrade -i -n network-observability --atomic grafana ./grafana
```

```shell
export cluster_uuid=$(oc get clusterversions.config.openshift.io version -o jsonpath='{.spec.clusterID}{"\n"}')
export infra_id=$(oc get infrastructures.config.openshift.io cluster -o jsonpath='{.status.infrastructureName}{"\n"}')
export region=$(oc get machines -n openshift-machine-api | grep -m 1 master | awk '{print $4}')
export azs=$(oc get machines -n openshift-machine-api | grep master | awk '{print $5}')
for az in $azs; do
  az=$az envsubst < elasticserach-machines.yaml | oc apply -f - -n openshift-machine-api
done
oc apply -f logging-operators.yaml
oc apply -f cluster-logging.yaml
or
oc apply -f cluster-logging-ocs.yaml
```

```sh
oc apply -f logging-operators.yaml
oc apply -f cluster-logging.yaml
oc apply -f log-forwarding.yaml
oc process -f event-router.yaml | oc apply -n openshift-logging -f -
```

loki
```sh
oc apply -f loki-operator.yaml
```

network observability operator

```sh
oc apply -f minio.yaml
```

network policy demo
https://examples.openshift.pub/networking/network-policy/network-policy-demo/

```sh
oc apply -k https://github.com/openshift-examples/network-policy-demo.git/deployment/
```
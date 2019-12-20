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
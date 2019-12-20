# Rook

## deploy ceph VMs

```shell
export cluster_uuid=$(oc get clusterversions.config.openshift.io version -o jsonpath='{.spec.clusterID}{"\n"}')
export infra_id=$(oc get infrastructures.config.openshift.io cluster -o jsonpath='{.status.infrastructureName}{"\n"}')
export region=$(oc get machines -n openshift-machine-api | grep -m 1 master | awk '{print $4}')
export azs=$(oc get machines -n openshift-machine-api | grep master | awk '{print $5}')
for az in $azs; do
  az=$az envsubst < rook-machines.yaml | oc apply -f - -n openshift-machine-api
done
```

to delete the machines:

```shell
for az in $azs; do
  az=$az envsubst < rook-machines.yaml | oc delete -f - -n openshift-machine-api
done
```

## deploy storage operator

```shell
oc apply -f https://raw.githubusercontent.com/openshift/ocs-operator/release-4.2/deploy/deploy-with-olm.yaml
```

## deploy OCS cluster

you can do it via WebUI.

cluster will be created in nodes with this label `cluster.ocs.openshift.io/openshift-storage=""`

```shell
oc apply -f ocs_cluster.yaml
```


debug ceph

```shell
curl -s https://raw.githubusercontent.com/rook/rook/release-1.1/cluster/examples/kubernetes/ceph/toolbox.yaml | sed 's/namespace: rook-ceph/namespace: openshift-storage/g'| oc apply -f -
TOOLS_POD=$(oc get pods -n openshift-storage -l app=rook-ceph-tools -o name)
oc rsh -n openshift-storage $TOOLS_POD
```
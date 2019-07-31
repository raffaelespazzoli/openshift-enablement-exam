deploy ceph operator

```
oc new-project rook-ceph
helm fetch https://charts.rook.io/release/rook-ceph-v1.0.4.tgz
helm template --namespace rook-ceph rook-ceph-v1.0.4.tgz | oc apply -f - -n rook-ceph
oc set env deployment/rook-ceph-operator ROOK_HOSTPATH_REQUIRES_PRIVILEGED=true -n rook-ceph
```

deploy ceph VMs
```
export cluster_uuid=$(oc get clusterversions.config.openshift.io version -o jsonpath='{.spec.clusterID}{"\n"}')
export infra_id=$(oc get infrastructures.config.openshift.io cluster -o jsonpath='{.status.infrastructureName}{"\n"}')
export region=$(oc get machines -n openshift-machine-api | grep -m 1 master | awk '{print $5}')
export azs=$(oc get machines -n openshift-machine-api | grep master | awk '{print $6}')
for az in $azs; do
  az=$az envsubst < rook-machines.yaml | oc apply -f - -n openshift-machine-api
done
```

deploy ceph cluster
```
oc apply -f ceph-cluster.yaml -n rook-ceph
```

consider
```
$ CLUSTER_UUID=$(oc get clusterversions.config.openshift.io version -o jsonpath='{.spec.clusterID}{"\n"}')
$ INFRA_ID=$(oc get infrastructures.config.openshift.io cluster -o jsonpath='{.status.infrastructureName}{"\n"}')
```
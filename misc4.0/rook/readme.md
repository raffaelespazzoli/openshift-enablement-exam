deploy ceph operator

```
oc new-project rook-ceph
helm fetch https://charts.rook.io/release/rook-ceph-v1.0.4.tgz
helm template --namespace rook-ceph rook-ceph-v1.0.4.tgz | oc apply -f - -n rook-ceph
oc set env deployment/rook-ceph-operator ROOK_HOSTPATH_REQUIRES_PRIVILEGED=true -n rook-ceph
```

deploy ceph VMs
```
export master_machine=$(oc get machines -n openshift-machine-api | grep -m 1 master | awk '{print $1}')
export cluster_id=${master_machine:8:15}
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
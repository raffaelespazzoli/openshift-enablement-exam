deploy ceph operator

```
oc new-project rook-ceph
oc apply -f rook-scc.yaml
helm repo add rook-release https://charts.rook.io/release
helm repo update
helm fetch rook-release/rook-ceph
helm template --namespace rook-ceph rook-ceph-v1.0.4.tgz -f rook-ceph-chart-values.yaml | oc apply -f - -n rook-ceph
oc set env deployment/rook-ceph-operator ROOK_ALLOW_MULTIPLE_FILESYSTEMS=false ROOK_ENABLE_FSGROUP=true ROOK_HOSTPATH_REQUIRES_PRIVILEGED=true ROOK_DISABLE_DEVICE_HOTPLUG=false ROOK_ENABLE_SELINUX_RELABELING=true -n rook-ceph
oc set image deployment/rook-ceph-operator rook-ceph-operator=rook/ceph:master -n rook-ceph
oc apply -f rook-ceph-cmd-reporter.yaml
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

for master use:
```
oc new-project rook-ceph
helm repo add rook-master https://charts.rook.io/master
helm repo update
helm search rook-ceph
helm fetch rook-master/rook-ceph --version v1.0.0
helm template --namespace rook-ceph rook-ceph-v1.0.0.tgz | oc apply -f - -n rook-ceph
oc set env deployment/rook-ceph-operator ROOK_HOSTPATH_REQUIRES_PRIVILEGED=true -n rook-ceph
```

# hyperconverged storage with ceph installed in openshift
this tutorial will explore the various aspects of ceph installed in openshift.

*credits*:  this is a porting to openshift of the excellent work done [here](https://github.com/ceph/ceph-docker)


# Create a ceph cluster

export your network config (use your SDN netowrk cidr), this is necessary only during the secret creation
```
export osd_cluster_network=10.1.0.0/16
export osd_public_network=10.1.0.0/16
```

generate keyrings and import as secrets 
```
cd generator
./generate_secrets.sh all `./generate_secrets.sh fsid`

oc new-project ceph

oc create secret generic ceph-conf-combined --from-file=ceph.conf --from-file=ceph.client.admin.keyring --from-file=ceph.mon.keyring --namespace=ceph
oc create secret generic ceph-bootstrap-rgw-keyring --from-file=ceph.keyring=ceph.rgw.keyring --namespace=ceph
oc create secret generic ceph-bootstrap-mds-keyring --from-file=ceph.keyring=ceph.mds.keyring --namespace=ceph
oc create secret generic ceph-bootstrap-osd-keyring --from-file=ceph.keyring=ceph.osd.keyring --namespace=ceph
oc create secret generic ceph-client-key --from-file=ceph-client-key --namespace=ceph

cd ..
```
label your nodes where you want ceph the storage servers to be installed for example:
```
oc label node node1.c.united-sandbox-151818.internal  node-type=storage
oc label node node2.c.united-sandbox-151818.internal  node-type=storage
oc label node node3.c.united-sandbox-151818.internal  node-type=storage
```
install ceph osd and mon
```
oc create imagestream ceph-daemon
oc tag docker.io/ceph/daemon:latest ceph/ceph-daemon:latest
oc create serviceaccount ceph
oc adm policy add-scc-to-user privileged -z ceph
oc adm policy add-scc-to-user anyuid -z default
oc policy add-role-to-user view -z default
oc policy add-role-to-user view -z ceph
oc create secret docker-registry default-internal-registry --docker-server=docker-registry.default.svc.cluster.local:5000 --docker-username=ceph --docker-password=`oc serviceaccounts get-token default` --docker-email=default@ceph.com
oc secrets link ceph default-internal-registry --for=pull


oc create -f ceph-mon-v1-svc.yaml
oc create -f ceph-mon-v1-dp.yaml
#oc create -f ceph-mon-check-v1-dp.yaml ??
oc create -f ceph-osd-v1-ds.yaml
```
test the cluster health
```
oc rsh <mon_pod> ceph -s
```
# Provisioning rbd volumes

##create a statically provisioned rbd persistent volume
```
oc project ceph
ADMIN_KEYRING=$(kubectl exec <mon-pod> -- ceph auth get client.admin 2>&1 | awk '/key =/ {print$3}')
oc new-project rbd-test
oc create secret generic ceph-admin-secret --from-literal=key="${ADMIN_KEYRING}"
oc rsh <mon pod> rbd create ceph-rbd-pv-test --size 10G
oc create -f rbd-pv.yaml
oc create -f rbd-pv-claim.yaml
oc create -f rbd-pvc-pod.yaml
```
##create a dynamically provisioned rbd persistent volume

create the admin keyring and secret (this is used by kubernetes to create volumes)
```
oc project ceph
ADMIN_KEYRING=$(kubectl exec <mon-pod> -- ceph auth get client.admin 2>&1 | awk '/key =/ {print$3}')
oc create secret generic ceph-admin-secret --type=kubernetes.io/rbd --from-literal=key="${ADMIN_KEYRING}"
```
create a pool, a user that can mount that volumes from that pool and that user keyring
```
oc rsh ${MON_POD_NAME} ceph osd pool create kube 64
oc rsh ${MON_POD_NAME} ceph auth get-or-create client.kube mon 'allow r' osd 'allow rwx pool=kube'
KUBE_KEYRING=$(oc rsh ${MON_POD_NAME} ceph auth get client.kube 2>&1 | awk '/key =/ {print$3}')

```
create the storage class, in this case we create a default storage class
```
oc create -f rbd-storage-class.yaml
```
create a new project, create a secret with the previous keyring. this secret must exists in the namespace of the pod that is trying to use the volume.
```
oc new-project test-dynamic-pv-ceph
oc create secret generic ceph-secret-user --from-literal=key="${KUBE_KEYRING}" --type=kubernetes.io/rbd

```
now you can start PVCs

# Provisioning the cephfs volumes

install the file server mds
```
oc create -f ceph-mds-v1-dp.yaml
```
create a statically provisioned cephfs persistent volume
```
oc project ceph
ADMIN_KEYRING=$(kubectl exec <mon-pod> -- ceph auth get client.admin 2>&1 | awk '/key =/ {print$3}')
oc new-project cephfs-test
oc create secret generic ceph-admin-secret --from-literal=key="${ADMIN_KEYRING}"
oc create -f cephfs-pv.yaml
oc create -f cephfs-pv-claim.yaml
oc create -f cephfs-pvc-pod.yaml
```
create a dynamically provisioned cephfs persistent volume
```
TBD
```
# Object store server

install the object store gateway
```
oc create -f ceph-rgw-v1-svc.yaml -f ceph-rgw-v1-dp.yaml
```
test the object store
```
TBD
```
set the regristry to use the ceph object store
```
TDB
```

# Monitoring
install the calamari management console
```
oc new-app --docker-image=minshenglin/calamari-docker --name=calamari
 
oc new-app --docker-image=kairen/docker-calamari-server:1.3.1 --name=calamari
oc expose svc calamari
```

# My  notes

https://access.redhat.com/articles/2184551

```
oc new-build --strategy=docker --name=cephrh7 https://github.com/ceph/ceph-docker --context-dir=ceph-releases/jewel/redhat/7.2
```
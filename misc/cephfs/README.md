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
export MON_POD_NAME=`oc get pods | grep -m1 ceph-mon | awk '{print $1}'`
oc rsh ${MON_POD_NAME} ceph -s
```
# Provisioning rbd volumes

## create a pool and prepare secrets

create the admin keyring and secret (this is used by kubernetes to create volumes in dynamic provisioning)
```
oc project ceph
ADMIN_KEYRING=$(kubectl exec ${MON_POD_NAME}-- ceph auth get client.admin 2>&1 | awk '/key =/ {print$3}')
oc create secret generic ceph-admin-secret --type=kubernetes.io/rbd --from-literal=key="${ADMIN_KEYRING}"
```
create a pool, a user that can mount that volumes from that pool and that user keyring
```
oc rsh ${MON_POD_NAME} ceph osd pool create kube 64
oc rsh ${MON_POD_NAME} ceph auth get-or-create client.kube mon 'allow r' osd 'allow rwx pool=kube'
KUBE_KEYRING=$(oc rsh ${MON_POD_NAME} ceph auth get client.kube 2>&1 | awk '/key =/ {print$3}')

```

##create a statically provisioned rbd persistent volume
```
oc project ceph
oc rsh ${MON_POD_NAME} rbd create ceph-rbd-pv-test -p kube --size 10G

oc new-project rbd-test
oc create secret generic ceph-kube-secret --from-literal=key="${KUBE_KEYRING}"
oc create -f rbd-pv.yaml
oc create -f rbd-pv-claim.yaml
oc create -f rbd-pvc-pod.yaml
```
##create a dynamically provisioned rbd persistent volume

create the storage class, in this case we create a default storage class
```
oc project ceph
oc create -f rbd-storage-class.yaml
```
create a new project, create a secret with the previous keyring. this secret must exists in the namespace of the pod that is trying to use the volume.
```
oc new-project test-dynamic-pv-ceph
oc create secret generic ceph-secret-user --from-literal=key="${KUBE_KEYRING}" --type=kubernetes.io/rbd

```
now you can start PVCs

to avoid creating a secret every time you create a new project you can follow this tutorial to modify the project template https://docs.openshift.com/container-platform/3.4/admin_guide/managing_projects.html#modifying-the-template-for-new-projects



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

# Object store server

install the object store gateway
```
oc create -f ceph-rgw-v1-svc.yaml -f ceph-rgw-v1-dp.yaml
oc set env dc/router ROUTER_ALLOW_WILDCARD_ROUTES=true -n default
oc expose svc ceph-rgw --port=8080
cat << EOF | oc create -f -
apiVersion: v1
kind: Route
metadata:
  labels:
    app: ceph
    daemon: rgw
  name: ceph-rgw-wildcard
spec:
  host: wildcard.ceph-rgw-ceph.apps.gc1.raffa.systems
  port:
    targetPort: 8080
  to:
    kind: Service
    name: ceph-rgw
  wildcardPolicy: Subdomain
EOF

```
test the object store
```
curl `oc get route | grep ceph-rgw | awk '{print $2}'`
```

set the registry to use the ceph object store (you probably shouldn't do this, but it's an effective way to test the S3 API)
```
export RGW_POD_NAME=`oc get pods | grep -m1 ceph-rgw | awk '{print $1}'`
oc rsh ${RGW_POD_NAME} radosgw-admin user create --uid=registry-user --display-name="Registry User" --email=registry-user@example.com --access-key=key --secret=secret
```
grab the access key and secret key. put them in the registry-s3/registry-config.yaml file and use them in the following commands
```
export ACCESS_KEY=key
export SECRET_KEY=secret
yum install -y s3cmd
export RGW_URL=`oc get route ceph-rgw | grep ceph-rgw | awk '{print $2}'`
#s3cmd --host=http://$RGW_URL --host-bucket=http://registry-bucket.$RGW_URL --region=not-used --access_key=$ACCESS_KEY --secret_key=$SECRET_KEY mb s3://registry-bucket
#mc config host add ceph http://`oc get route | grep ceph-rgw | awk '{print $2}'`:80 $ACCESS_KEY $SECRET_KEY
#mc mb s3/registry-bucket
This doesn't work
```
remember if you issue the following, you'll loose the content of your registry.
```
oc scale dc docker-registry --replicas=0 -n default
oc secrets new registry-config config.yml=registry-config.yaml -n default
oc volume dc/docker-registry --remove --name=registry-storage -n default
oc volume dc/docker-registry --add --type=secret --secret-name=registry-config -m /etc/docker/registry/ -n default
oc env dc/docker-registry REGISTRY_CONFIGURATION_PATH=/etc/docker/registry/config.yml -n default
oc deploy docker-registry --latest -n default
oc scale dc docker-registry --replicas=2 -n default
```

# Monitoring
install the calamari management console
```
oc new-build --strategy=docker --name=calamari
oc new-app
#oc new-app --docker-image=minshenglin/calamari-docker --name=calamari-server
#oc new-app --docker-image=kairen/docker-calamari-server:1.3.1 --name=calamari
#oc expose svc calamari-server
```

# My  notes

https://access.redhat.com/articles/2184551

```
oc new-build --strategy=docker --name=cephrh7 https://github.com/ceph/ceph-docker --context-dir=ceph-releases/jewel/redhat/7.2
```

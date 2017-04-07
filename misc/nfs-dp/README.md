# NFS dynamic provisioning in openshift

this will create an NFS server with dynamic provisioning enabled running on a pod that will serve data our of an export directory mounted from a hostfile (/export2, you can change it)
You will need oc client v1.4, I believe the server can be 3.3, but I tested only with 3.4. 

```
oc new-project nfs-provisioner
oc create sa nfs-provisioner
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/nfs-dp/nfs-provisioner-scc.yaml
oc adm policy add-scc-to-user nfs-provisioner -z nfs-provisioner
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:nfs-provisioner:nfs-provisioner
oc adm policy add-cluster-role-to-user system:pv-provisioner-controller system:serviceaccount:nfs-provisioner:nfs-provisioner
oc adm policy add-cluster-role-to-user system:pv-binder-controller system:serviceaccount:nfs-provisioner:nfs-provisioner
oc adm policy add-cluster-role-to-user system:pv-recycler-controller system:serviceaccount:nfs-provisioner:nfs-provision
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/nfs-dp/nfs-provisioner-class.yaml
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/nfs-dp/nfs-provisioner-dc.yaml
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/nfs-dp/nfs-provisioner-pvc.yaml
```

if you want to create a default storage class for your cluster run
```
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/nfs-dp/nfs-provisioner-class-default.yaml
```

# Adding NFS DP to cdk 3.0

oc cluster up --host-data-dir=/var/lib/origin/openshift.data.dir --image="registry.access.redhat.com/openshift3/ose" --version=v3.4


# Adding NFS DP to minishift

create an host folder pointing to a folder on your laptop 
```
minishift hostfolder add nfsdp
```
start the minishift cluster
minishift start --cpus 2 --memory 12288 --vm-driver virtualbox


# NFS dynamic provisioning in openshift

this will create an NFS server with dynamic provisiong enabled running on a pod that will serve data our of an export directory mounted from a hostfile (/export2, you can change it)

```
oc create sa nfs-provisioner
oc create -f ???
o


# NFS dynamic provisioning in openshift

this will create an NFS server with dynamic provisiong enabled running on a pod that will serve data our of an export directory mounted from a hostfile (/export2, you can change it)

```
oc create sa nfs-provisioner
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/nfs-dp/nfs-provisioner-class.yaml
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/nfs-dp/nfs-provisioner-dc.yaml
oc create -f https://github.com/raffaelespazzoli/openshift-enablement-exam/blob/master/misc/nfs-dp/nfs-provisioner-pvc.yaml
```


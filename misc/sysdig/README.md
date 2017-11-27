#sysdig installation

edit the sysdig-ds.yaml file with your sysdig-cloud key 

```
oc adm new-project sysdigcloud --node-selector=""
oc create serviceaccount sysdigcloud
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:sysdigcloud:sysdigcloud
oc adm policy add-scc-to-user privileged system:serviceaccount:sysdigcloud:sysdigcloud
oc create -f sysdig-ds.yaml​
```
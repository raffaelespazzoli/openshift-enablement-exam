preparing for snapshotting:

create the storage class
```
oc apply -f ./snapshot-storage-class.yaml
```
create the snapshot
```
oc apply -f ./snapshot.yaml
```
restore
```
oc apply -f restore.yaml
```

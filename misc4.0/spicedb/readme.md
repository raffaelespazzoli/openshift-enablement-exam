# SpiceDB

```shell
oc apply --server-side -k github.com/authzed/spicedb-operator/config
oc apply -f ./spicedb.yaml -n spicedb-operator
oc expose service dev -n spicedb-operator
```

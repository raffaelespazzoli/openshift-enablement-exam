# SpiceDB

```shell
oc apply --server-side -k github.com/authzed/spicedb-operator/config
oc new-project spicedb-test
```

Deploy cockroachdb

```shell
oc apply -f https://raw.githubusercontent.com/cockroachdb/cockroach/master/cloud/kubernetes/cockroachdb-statefulset.yaml
oc apply -f https://raw.githubusercontent.com/cockroachdb/cockroach/master/cloud/kubernetes/cluster-init.yaml

#oc run cockroachdb -it --image=cockroachdb/cockroach:v22.1.8 --rm --restart=Never -- sql --insecure --host=cockroachdb-public
#CREATE USER dba WITH PASSWORD dba;
#GRANT admin TO dba WITH ADMIN OPTION;
oc expose service cockroachdb-public --port 8080
```

deploy postgresql

```shell
oc apply -f postgresql-deployment.yaml -n spicedb-test
```

deploy spicedb without operator

```shell
oc apply -f spicedb-deployment.yaml -n spicedb-test
```

deploy spicedb with the operator

```shell
oc apply -f ./spicedb.yaml -n spicedb-test
oc expose service dev -n spicedb-test
```

deploy via helm chart

```shell
helm upgrade -i --create-namespace myspicedb ./charts/spicedb -n spicedb-test
```

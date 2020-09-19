https://medium.com/searce/sql-server-alwayson-availability-groups-on-google-kubernetes-engine-gke-df442f3da552

## Helm chart approach

```shell
export namespace=mssql
helm upgrade mssql stable/mssql-linux -i --create-namespace -n ${namespace} -f ./values.yaml
```


## Operator approach (does not work)

```shell
export namespace=mssql
oc new-project ${namespace}
envsubst < ./operator.yaml | oc apply -f - -n ${namespace}
oc apply -f pvc.yaml -n ${namespace}
oc apply -f mssql.yaml -n ${namespace}
```
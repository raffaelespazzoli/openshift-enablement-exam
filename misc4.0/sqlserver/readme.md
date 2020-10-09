https://medium.com/searce/sql-server-alwayson-availability-groups-on-google-kubernetes-engine-gke-df442f3da552

https://github.com/microsoft/sqlworkshops-sqlonopenshift

https://catalog.redhat.com/software/containers/mssql/rhel/server/5ba50865f5a0de06555a2ee7

https://github.com/Microsoft/mssql-docker

## Helm chart approach

```shell
export namespace=mssql
oc adm policy add-scc-to-user anyuid -z default -n ${namespace}
helm upgrade mssql ./charts/mssql-linux -i --create-namespace -n ${namespace} -f ./values.yaml
```


## Operator approach (does not work)

```shell
export namespace=mssql
oc new-project ${namespace}
envsubst < ./operator.yaml | oc apply -f - -n ${namespace}
oc apply -f pvc.yaml -n ${namespace}
oc apply -f mssql.yaml -n ${namespace}
```
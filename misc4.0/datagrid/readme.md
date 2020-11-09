# Datagrid

## Install the operator

```shell
export project=datagrid
oc new-project ${project}
envsubst < ./operator.yaml | oc apply -f - -n ${project}
```

## Create the datagrid cluster

```shell
oc apply -f datagrid.yaml -n ${project}
export developer_password=$(oc get secret datagrid-generated-secret -o jsonpath="{.data.identities\.yaml}" | base64 -d | yq -r .credentials[0].password)
```

## Test datagrid

```shell
oc import-image ubi8/openjdk-11 --from=registry.access.redhat.com/ubi8/openjdk-11 --confirm -n ${project}
oc new-app openjdk-11~https://github.com/raffaelespazzoli/redhat-datagrid-tutorials --context-dir=spring-integration/spring-boot/remote --name springboot-datagrid -n ${project}
envsubst < application-properties.yaml | oc apply -f - -n ${project}
oc set volume deployment/springboot-datagrid --add --configmap-name=application-properties --mount-path=/config --name=config -t configmap -n ${project}
oc set env deployment/springboot-datagrid SPRING_CONFIG_LOCATION=/config/application.properties
```
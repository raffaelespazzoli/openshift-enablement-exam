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
export developer_password=$(oc get secret datagrid-generated-secret -o jsonpath="{.data.identities\.yaml}" -n datagrid | base64 -d | yq -r .credentials[0].password)
```

## Test datagrid

```shell
oc new-app registry.redhat.io/ubi8/openjdk-11~https://github.com/raffaelespazzoli/redhat-datagrid-tutorials --context-dir=spring-integration/spring-boot/remote --name springboot-datagrid -n ${project}
envsubst < application-properties.yaml | oc apply -f - -n ${project}
oc set volume deploymentconfig/springboot-datagrid --add --configmap-name=application-properties --mount-path=/config --name=config -t configmap -n ${project}
oc set env deploymentconfig/springboot-datagrid SPRING_CONFIG_LOCATION=/config/application.properties
```

## Misc

### How to add pull secret for registry.redhat.io

See <https://access.redhat.com/RegistryAuthentication>

```sh
docker login registry.redhat.io
cp ~/.docker/config.json .
oc create secret generic registry.redhat.io \
    --from-file=.dockerconfigjson=config.json \
    --type=kubernetes.io/dockerconfigjson
oc secrets link default registry.redhat.io --for=pull
oc secrets link builder registry.redhat.io
```

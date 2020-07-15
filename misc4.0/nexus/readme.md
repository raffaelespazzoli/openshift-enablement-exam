# Deploy nexus

```shell
export namespace=nexus
oc new-project ${namespace}
helm repo add oteemocharts https://oteemo.github.io/charts
export guid=$(oc get project ${namespace} -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'|sed 's/\/.*//')
envsubst < ./values.yaml > /tmp/values.yaml
oc adm policy add-scc-to-user anyuid -z default -n ${namespace}
helm upgrade sonatype-nexus oteemocharts/sonatype-nexus -i -n ${namespace} -f /tmp/values.yaml
```


Deploy nexusIQ

```shell
helm upgrade nexusiq oteemocharts/nexusiq -i -n ${namespace}
```
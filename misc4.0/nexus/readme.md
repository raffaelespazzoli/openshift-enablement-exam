# Deploy nexus

```shell
export namespace=nexus
oc new-project ${namespace}
helm repo add oteemocharts https://oteemo.github.io/charts
export guid=$(oc get project ${namespace} -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'|sed 's/\/.*//')
envsubst < ./values.yaml > /tmp/values.yaml
helm upgrade sonatype-nexus oteemocharts/sonatype-nexus -i -n ${namespace} -f /tmp/values.yaml
```

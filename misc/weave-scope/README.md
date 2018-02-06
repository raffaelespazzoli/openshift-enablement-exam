```
oc adm new-project weave --node-selector=''
# Scope probe pods need full access to Kubernetes API via 'weave-scope' service account
oc adm policy add-cluster-role-to-user cluster-admin -z weave-scope
# Scope probe pods also need to run as priviliaged containers, so grant 'priviliged' Security Context Constrains (SCC) for 'weave-scope' service account
oc adm policy add-scc-to-user privileged -z weave-scope
# Scope app has an init daemon that has to run as UID 0, so grant 'anyuid' SCC for 'default' service account
oc adm policy add-scc-to-user anyuid -z default

oc apply -f 'https://cloud.weave.works/k8s/scope.yaml'
oc expose service weave-scope-app
```
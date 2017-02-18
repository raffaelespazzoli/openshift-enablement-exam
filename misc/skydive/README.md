# OpenShift template for skydive agent

This OpenShift template allows you to instantiate skydive in OpenShift.


```
oc new-project skydive
oc patch namespace skydive --patch '{ "metadata":{"annotations": { "openshift.io/node-selector": "" }}}'
oc create configmap skydive-config --from-file=./skydive.yml
oc adm policy add-scc-to-user privileged -z default
oc process -f skydive-template.yaml | oc create -f -
oc expose svc skydive-analyzer
```


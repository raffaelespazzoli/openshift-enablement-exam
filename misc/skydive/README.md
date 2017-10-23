# OpenShift template for skydive agent

This OpenShift template allows you to instantiate skydive in OpenShift.


```
oc adm new-project skydive --node-selector=""
oc create configmap skydive-config --from-file=./skydive.yml
oc adm policy add-scc-to-user privileged -z default
oc process -f skydive-template.yaml | oc create -f -
oc expose svc skydive-analyzer
```


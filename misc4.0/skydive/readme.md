```shell
oc adm new-project skydive --node-selector=""
oc adm policy add-scc-to-user privileged -z default -n skydive
oc adm policy add-cluster-role-to-user cluster-reader -z default -n skydive
oc process -f template.yaml | oc apply -f - -n skydive
```
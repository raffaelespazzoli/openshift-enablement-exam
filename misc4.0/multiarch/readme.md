# Multiarch

```shell
oc new-project multiarch
oc adm policy add-scc-to-user privileged -z default -n multiarch
oc apply -f ./daemonset.yaml -n multiarch
```

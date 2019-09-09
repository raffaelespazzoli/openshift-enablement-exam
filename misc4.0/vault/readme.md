```shell
oc new-project vault
oc adm policy add-scc-to-user privileged -z vault -n vault
helm template vault-helm --name vault --namespace vault -f values.yaml | oc apply -f - -n vault
oc create route passthrough vault-ui --service vault-ui -n vault
```

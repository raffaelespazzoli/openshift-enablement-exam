```shell
oc new-project code-ready-workspaces
oc apply -f operators.yaml
oc apply -f checluster.yaml -n code-ready-workspaces
```

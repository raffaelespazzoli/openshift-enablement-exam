```shell
oc new-project code-ready-workspaces
export NAMESPACE=code-ready-workspaces
oc apply -f operators.yaml
oc create clusterrole codeready-operator --resource=oauthclients --verb=get,create,delete,update,list,watch
oc create clusterrolebinding codeready-operator --clusterrole=codeready-operator --serviceaccount=${NAMESPACE}:codeready-operator
oc create role secret-reader --resource=secrets --verb=get -n=openshift-ingress
oc create rolebinding codeready-operator --role=secret-reader --serviceaccount=${NAMESPACE}:codeready-operator -n=openshift-ingress
oc apply -f checluster.yaml -n code-ready-workspaces
```

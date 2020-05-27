# Install kube ops view

```shell
export OCP_OPS_VIEW_ROUTE=ocp-ops-view.apps.$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
oc new-project ocp-ops-view
oc adm policy add-scc-to-user anyuid -z default -n ocp-ops-view
helm install kube-ops-view stable/kube-ops-view --namespace ocp-ops-view --set redis.enabled=true --set rbac.create=true --set ingress.enabled=true --set ingress.hostname=$OCP_OPS_VIEW_ROUTE --set redis.master.port=6379
```
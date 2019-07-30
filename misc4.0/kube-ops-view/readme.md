```
export OCP_OPS_VIEW_ROUTE=ocp-ops-view.apps.$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
oc new-project ocp-ops-view
helm fetch stable/kube-ops-view
oc adm policy add-scc-to-user anyuid -z default -n ocp-ops-view
helm template kube-ops-view-1.0.0.tgz --name=kube-ops-view-stable --namespace ocp-ops-view --set redis.enabled=true --set rbac.create=true --set ingress.enabled=true --set ingress.hostname=$OCP_OPS_VIEW_ROUTE | oc apply -f -
```
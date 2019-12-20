```
export OCP_OPS_VIEW_ROUTE=ocp-ops-view.apps.$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
oc new-project ocp-ops-view
export kube_ops_view_chart_version=$(helm search stable/kube-ops-view | grep stable/kube-ops-view | awk '{print $2}')
helm fetch stable/kube-ops-view --version ${kube_ops_view_chart_version}
oc adm policy add-scc-to-user anyuid -z default -n ocp-ops-view
helm template kube-ops-view-${kube_ops_view_chart_version}.tgz --name=kube-ops-view-stable --namespace ocp-ops-view --set redis.enabled=true --set rbac.create=true --set ingress.enabled=true --set ingress.hostname=$OCP_OPS_VIEW_ROUTE | oc apply -f - -n ocp-ops-view
rm kube-ops-view-${kube_ops_view_chart_version}.tgz
```
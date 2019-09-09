```shell
oc create namespace kube-opex-analytics
oc adm policy add-scc-to-user anyuid -z kube-opex-analytics -n kube-opex-analytics
helm template --namespace kube-opex-analytics --name kube-opex-analytics helm/kube-opex-analytics/ | oc apply -f - -n kube-opex-analytics
oc expose service kube-opex-analytics
```
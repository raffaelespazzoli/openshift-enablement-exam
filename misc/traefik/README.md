# deploy Traefik

```
oc project kube-system
oc create sa traefik
oc adm policy add-scc-to-user hostnetwork -z traefik
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:kube-system:traefik
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/traefik/traefik-d.yaml
oc create -f https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/ui.yaml
```
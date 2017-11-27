# deploy Traefik

```
oc new-project traefik
oc create sa traefik
oc adm policy add-scc-to-user hostnetwork -z traefik
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:traefik:traefik
oc create -f traefik-dc.yaml
oc expose svc traefik-web-ui
```
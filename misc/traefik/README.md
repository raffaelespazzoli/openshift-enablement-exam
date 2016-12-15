# deploy Traefik

```
oc project kube-system
oc create sa traefik
oc adm policy add-scc-to-user hostnetwork -z traefik
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:kube-system:traefik
oc create -f https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/traefik.yaml
oc patch deployment/traefik-ingress-controller --patch '{"spec":{"template":{"spec":{"serviceAccountName": "traefik", "hostNetwork":false , "containers" : [ { "name":"traefik-ingress-lb", "ports" : [ {"name":"http","containerPort" : "8081" , "hostPort":"8081"}], "args": ["--web","--kubernetes","--entryPoints=Name:http Address::8081"]}] }}}}'

oc create -f traefik-d.yaml

oc create -f https://raw.githubusercontent.com/containous/traefik/master/examples/k8s/ui.yaml
```
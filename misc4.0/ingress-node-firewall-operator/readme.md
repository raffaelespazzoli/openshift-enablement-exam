```sh
oc apply -f ./operator.yaml
oc apply -f INFWConfig.yaml
# add the "do-node-ingress-firewall=true" label to a set of nodes, must be done in OCM for ROSA.
oc apply -f INFW.yaml
```
# SM + GRPC

```shell
oc apply -f operators.yaml
#oc apply -f cert-manager.yaml
helm upgrade -i \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.6.1 \
  --set installCRDs=true \
  --set "extraArgs={--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53}" \
  --set global.leaderElection.namespace=cert-manager
oc apply -f letsencrypt-issuer.yaml
oc new-project istio-system
oc apply -f mesh-certificate.yaml
oc apply -f control-plane.yaml
oc apply -f gateway.yaml
```

```shell
oc new-project test-grpc
oc apply -f servicemember.yaml -n test-grpc
```

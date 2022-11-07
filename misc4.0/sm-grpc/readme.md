# SM + GRPC

```shell
oc apply -f operators.yaml
helm upgrade -i \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.6.1 \
  --set installCRDs=true \
  --set "extraArgs={--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53}" \
  --set global.leaderElection.namespace=cert-manager
oc apply -f credential-request.yaml
export base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
export hosted_zone=$(oc get dns cluster -o jsonpath='{.spec.publicZone.id}')
export region=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.aws.region}')
export aws_key_id=$(oc get secret cert-manager-dns-credentials -n cert-manager -o jsonpath='{.data.aws_secret_access_key}' | base64 -d )
envsubst < letsencrypt-issuer.yaml | oc apply -f -
```

```shell
oc new-project test-grpc
oc apply -f servicemember.yaml -n test-grpc
```

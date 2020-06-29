# Setup external DNS in an AWS cluster

```shell
aws route53 create-hosted-zone
oc new-project external-dns
oc apply -f ./credentials.yaml -n external-dns
export cluster_base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
export global_base_domain=global.${cluster_base_domain#*.}

export hosted_zone_res=$(aws route53 create-hosted-zone --name ${global_base_domain} --caller-reference $(date +"%m-%d-%y-%H-%M-%S-%N") | jq -r .HostedZone.Id )
export hosted_zone_id=${hosted_zone_res##*/}

export aws_key=$(oc get secret external-dns-aws-kms-credentials -n external-dns -o jsonpath='{.data.aws_secret_access_key}' | base64 -d)
export aws_id=$(oc get secret external-dns-aws-kms-credentials -n external-dns -o jsonpath='{.data.aws_access_key_id}' | base64 -d)
export sguid=$(oc get project external-dns -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'| sed 's/\/.*//')
export uid=$(oc get project external-dns -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'| sed 's/\/.*//')
#helm repo add bitnami https://charts.bitnami.com/bitnami
#needed to fix route permission issue
git clone https://github.com/bitnami/charts
helm upgrade external-dns ./charts/bitnami/external-dns --create-namespace -i -n external-dns -f external-dns-values.yaml --set txtOwnerId=external-dns --set domainFilters[0]=${global_base_domain} --set aws.credentials.secretKey=${aws_key} --set aws.credentials.accessKey=${aws_id} --set podSecurityContext.fsGroup=${sguid} --set podSecurityContext.runAsUser=${uid} --set zoneIdFilters[0]=${hosted_zone_id}
```

test

```shell
oc apply -f route.yaml -n external-dns
dig external.apps.${global_base_domain}
```

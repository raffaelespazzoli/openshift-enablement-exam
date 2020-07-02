# Setup external DNS in an AWS cluster

```shell
aws route53 create-hosted-zone
oc new-project external-dns
oc apply -f ./credentials.yaml -n external-dns
export cluster_base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
export cluster_zone_id=$(oc get dns cluster -o jsonpath='{.spec.publicZone.id}')
export global_base_domain=global.${cluster_base_domain#*.}
aws route53 create-hosted-zone --name ${global_base_domain} --caller-reference $(date +"%m-%d-%y-%H-%M-%S-%N") 
export global_zone_res=$(aws route53 list-hosted-zones-by-name --dns-name ${global_base_domain} | jq -r .HostedZones[0].Id )
export global_zone_id=${global_zone_res##*/}
export delegation_record=$(aws route53 list-resource-record-sets --hosted-zone-id ${global_zone_id} | jq .ResourceRecordSets[0])
envsubst < delegation-record.json > /tmp/delegation-record.json
aws route53 change-resource-record-sets --hosted-zone-id ${cluster_zone_id} --change-batch file:///tmp/delegation-record.json


export aws_key=$(oc get secret external-dns-aws-kms-credentials -n external-dns -o jsonpath='{.data.aws_secret_access_key}' | base64 -d)
export aws_id=$(oc get secret external-dns-aws-kms-credentials -n external-dns -o jsonpath='{.data.aws_access_key_id}' | base64 -d)
export sguid=$(oc get project external-dns -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'| sed 's/\/.*//')
export uid=$(oc get project external-dns -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'| sed 's/\/.*//')
#helm repo add bitnami https://charts.bitnami.com/bitnami
#needed to fix route permission issue
git clone https://github.com/bitnami/charts
helm upgrade external-dns ./charts/bitnami/external-dns --create-namespace -i -n external-dns -f external-dns-values.yaml --set txtOwnerId=external-dns --set domainFilters[0]=${global_base_domain} --set aws.credentials.secretKey=${aws_key} --set aws.credentials.accessKey=${aws_id} --set podSecurityContext.fsGroup=${sguid} --set podSecurityContext.runAsUser=${uid} --set zoneIdFilters[0]=${global_zone_id}
```

test

```shell
oc apply -f route.yaml -n external-dns
dig external.apps.${global_base_domain}
```

test dns endpoint

```shell
oc apply -f dns-endpoint.yaml -n external-dns
```

Rael Garcia Arnes


## Emulation of three clusters in three namespaces

here we emulate having three cluster and a control plane cluster.

uninstall the previous external-dns if you have one, keep the global route zone.

Prepare the routers

```shell
for namespace in cluster1 cluster2 cluster3; do
  export namespace
  envsubst < router.yaml | oc apply -f -
done
oc patch ingresscontroller default -n openshift-ingress-operator -p '{"spec": {"labelSelector": {"matchExpressions": [{"key": "route", "operator": "NotIn", "values": ["global"]}]}}}' --type merge
```

Deploy external-dns

```shell
oc new-project control-cluster
export sguid=$(oc get project control-cluster -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'| sed 's/\/.*//')
export uid=$(oc get project control-cluster -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'| sed 's/\/.*//')
helm template external-dns ./charts/bitnami/external-dns --create-namespace -n control-cluster -f external-dns-values.yaml --set txtOwnerId=external-dns --set domainFilters[0]=${global_base_domain} --set aws.credentials.secretKey=${aws_key} --set aws.credentials.accessKey=${aws_id} --set podSecurityContext.fsGroup=${sguid} --set podSecurityContext.runAsUser=${uid} --set zoneIdFilters[0]=${global_zone_id} --set sources[0]=crd --set namespace=control-cluster | oc apply -f - -n control-cluster

oc new-project cluster1
export sguid=$(oc get project cluster1 -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'| sed 's/\/.*//')
export uid=$(oc get project cluster1 -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'| sed 's/\/.*//')
helm template external-dns ./charts/bitnami/external-dns --create-namespace -n cluster1 -f external-dns-values.yaml --set txtOwnerId=external-dns --set domainFilters[0]=${global_base_domain} --set aws.credentials.secretKey=${aws_key} --set aws.credentials.accessKey=${aws_id} --set podSecurityContext.fsGroup=${sguid} --set podSecurityContext.runAsUser=${uid} --set zoneIdFilters[0]=${global_zone_id} --set sources[0]=openshift-route --set fqdnTemplates='cluster1-{{ .spec.host }}' --set namespace=cluster1 | oc apply -f - -n cluster1

oc new-project cluster2
export sguid=$(oc get project cluster2 -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'| sed 's/\/.*//')
export uid=$(oc get project cluster2 -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'| sed 's/\/.*//')
helm template external-dns ./charts/bitnami/external-dns --create-namespace -n cluster2 -f external-dns-values.yaml --set txtOwnerId=external-dns --set domainFilters[0]=${global_base_domain} --set aws.credentials.secretKey=${aws_key} --set aws.credentials.accessKey=${aws_id} --set podSecurityContext.fsGroup=${sguid} --set podSecurityContext.runAsUser=${uid} --set zoneIdFilters[0]=${global_zone_id} --set sources[0]=openshift-route --set fqdnTemplates='cluster2-{{ .spec.host }}' --set namespace=cluster2 | oc apply -f - -n cluster1

oc new-project cluster3
export sguid=$(oc get project cluster3 -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'| sed 's/\/.*//')
export uid=$(oc get project cluster3 -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'| sed 's/\/.*//')
helm template external-dns ./charts/bitnami/external-dns --create-namespace -n cluster3 -f external-dns-values.yaml --set txtOwnerId=external-dns --set domainFilters[0]=${global_base_domain} --set aws.credentials.secretKey=${aws_key} --set aws.credentials.accessKey=${aws_id} --set podSecurityContext.fsGroup=${sguid} --set podSecurityContext.runAsUser=${uid} --set zoneIdFilters[0]=${global_zone_id} --set sources[0]=openshift-route --set fqdnTemplates='cluster3-{{ .spec.host }}' --set namespace=cluster3 | oc apply -f - -n cluster3
```

deploy routes and dnsrecord
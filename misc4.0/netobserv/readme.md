# Deploy network observability

## Install operator

```shell
oc adm new-project openshift-netobserv-operator 
oc adm new-project openshift-operators-redhat
oc label namespace openshift-operators-redhat openshift.io/cluster-monitoring=true
oc label namespace openshift-netobserv-operator openshift.io/cluster-monitoring=true
oc new-project netobserv
oc apply -f ./operator.yaml
oc create secret generic -n netobserv lokistack-dev-s3 \
  --from-literal=bucketnames="loki-flow-logs" \
  --from-literal=endpoint="https://loki-flow-logs.s3.us-east-2.amazonaws.com" \
  --from-literal=access_key_id="${AWS_ACCESS_KEY_ID}" \
  --from-literal=access_key_secret="${AWS_ACCESS_KEY_SECRET}" \
  --from-literal=sse_type="SSE-S3" \
  --from-literal=region="us-east-2"
oc apply -f ./loki.yaml
oc apply -f ./loki-rbac.yaml
oc apply -f ./flow-collector.yaml
#oc apply -f ./operator-grafana.yaml -n network-observability
```

Note, for the admin view to work the user need to belong to one of three specific groups: 
system:cluster-admins
cluster-admin
dedicated-admin
see also: https://access.redhat.com/solutions/7018952


## enable minio

```sh
oc adm policy add-scc-to-user nonroot-v2 -z loki-sa -n netobserv
oc apply -f ./minio/tenant.yaml -n netobserv
```

## Install grafana

```shell
helm upgrade -i -n network-observability --atomic grafana ./grafana
```

# Crossplane

## Install the operator

```shell
oc new-project upbound-system
oc apply -f ./operator.yaml -n upbound-system
```

## Providers

### Google Provider

```shell
export project_id=$(cat ~/.gcp/osServiceAccount.json | jq -r .project_id)
oc create secret generic gcp-provider-creds --from-file ~/.gcp/osServiceAccount.json -n upbound-system
envsubst < ./gcp-provider.yaml | oc apply -f - -n upbound-system
export sa_name=$(oc get sa -n upbound-system | grep provider-gcp | awk '{ print $1 }' )
oc adm policy add-scc-to-user nonroot -z ${sa_name} -n upbound-system
```
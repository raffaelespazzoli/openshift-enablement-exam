# Crossplane

## helm -based intallation

```sh
helm repo add crossplane-stable https://charts.crossplane.io/stable
helm repo update
helm upgrade crossplane -i --namespace crossplane-system --create-namespace crossplane-stable/crossplane
oc adm policy add-scc-to-group nonroot system:serviceaccounts:crossplane-system -n crossplane-system
oc apply -f ./aws-provider-novault.yaml
oc create secret generic aws-secret -n crossplane-system --from-file=creds=./aws-credentials.txt
oc apply -f ./aws-provider-config.yaml
oc apply -f ./aws-platform-ref.yaml
oc create -f s3-bucket.yaml
```

## Install Vault

```sh
helm repo add hashicorp https://helm.releases.hashicorp.com
oc new-project vault
oc adm policy add-role-to-user admin -z vault -n vault
export cluster_base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
helm upgrade vault hashicorp/vault -i --create-namespace -n vault --atomic -f ./config/local-development/vault-values.yaml --set server.route.host=vault-vault.apps.${cluster_base_domain}
```

## Prepare Vault to be used with crossplane

```sh

## Configure Crossplane to use Vault

```sh
helm upgrade -i ess-plugin-vault ./charts/ess-plugin-vault --namespace crossplane-system -f vault-plugin-values.yaml
oc apply -f ./controller-config.yaml
oc apply -f ./vault-config.yaml
oc apply -f ./store-config.yaml
oc apply -f ./provider-store-config.yaml
```
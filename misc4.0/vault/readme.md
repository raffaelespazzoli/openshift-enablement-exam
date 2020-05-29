# Install Vault

This script will install Vault in HA with raft based storage and auto-unseal. The auto-unseal process will used a non-ha seed vault for the initial secret.

## Preparation

Create vault namespace

```shell
git clone https://github.com/hashicorp/vault-helm
oc new-project vault
oc adm policy add-scc-to-user nonroot -z vault -n vault
export sguid=$(oc get project vault -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.supplemental-groups}'|sed 's/\/.*//')
export uid=$(oc get project vault -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'|sed 's/\/.*//')
```

Deploy cert-manager

```shell
oc new-project cert-manager
oc apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.15.0/cert-manager.yaml
```

Deploy needed certificates

```shell
oc apply -f ./vault-certs.yaml -n vault
```

## Install the seed-vault

```shell
helm template seed-vault ./vault-helm -n vault -f ./seed-values.yaml --set server.gid=${sguid} --set server.uid=${uid} | oc apply -f -
```

## Initialize seed-vault

this is a good tutorial: https://learn.hashicorp.com/vault/operations/raft-storage

```shell
SEED_INIT_RESPONSE=$(oc exec seed-vault-0 -n vault -- vault operator init -address https://seed-vault:8200 -ca-path /etc/vault-tls/seed-vault-tls/ca.crt -format=json -key-shares=1 -key-threshold=1)

SEED_UNSEAL_KEY=$(echo "$SEED_INIT_RESPONSE" | jq -r .unseal_keys_b64[0])
SEED_VAULT_TOKEN=$(echo "$SEED_INIT_RESPONSE" | jq -r .root_token)

echo "$SEED_UNSEAL_KEY"
echo "$SEED_VAULT_TOKEN"

#here we are saving these variable in a secret, this is probably not what you should do in a production environment
oc create secret generic seed-vault-init -n vault --from-literal=unseal_key=${SEED_UNSEAL_KEY} --from-literal=root_token=${SEED_VAULT_TOKEN}

#execute only this step after a restart of the pod
oc exec seed-vault-0 -n vault -- vault operator unseal -address https://seed-vault:8200 -ca-path /etc/vault-tls/seed-vault-tls/ca.crt "$SEED_UNSEAL_KEY"

oc exec seed-vault-0 -n vault -- sh -c "VAULT_TOKEN=${SEED_VAULT_TOKEN} vault secrets enable -address https://seed-vault:8200 -ca-path /etc/vault-tls/seed-vault-tls/ca.crt transit"
oc exec seed-vault-0 -n vault -- sh -c "VAULT_TOKEN=${SEED_VAULT_TOKEN} vault write -address https://seed-vault:8200 -ca-path /etc/vault-tls/seed-vault-tls/ca.crt -f transit/keys/unseal_key"
```

## Install HA-vault

```shell
export SEED_VAULT_TOKEN
export ca_crt=$(oc get secret vault-tls -n vault -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/^/        /')
envsubst < values.yaml.template > values.yaml
helm template vault ./vault-helm -n vault -f ./values.yaml --set server.gid=${sguid} --set server.uid=${uid} --set injector.gid=${sguid} --set injector.uid=${uid} | oc apply -f -
```

## Initialize HA-vault

```shell
HA_INIT_RESPONSE=$(oc exec vault-0 -n vault -- vault operator init -address https://vault-0.vault-internal:8200 -ca-path /etc/vault-tls/vault-tls/ca.crt -format=json -recovery-shares 1 -recovery-threshold 1)

HA_UNSEAL_KEY=$(echo "$HA_INIT_RESPONSE" | jq -r .recovery_keys_b64[0])
HA_VAULT_TOKEN=$(echo "$HA_INIT_RESPONSE" | jq -r .root_token)

echo "$HA_UNSEAL_KEY"
echo "$HA_VAULT_TOKEN"

#here we are saving these variable in a secret, this is probably not what you should do in a production environment
oc create secret generic vault-init -n vault --from-literal=unseal_key=${HA_UNSEAL_KEY} --from-literal=root_token=${HA_VAULT_TOKEN}
```

## Verify the cluster

```shell
oc exec vault-0 -n vault -- sh -c "VAULT_TOKEN=${HA_VAULT_TOKEN} vault operator raft list-peers -address https://vault-0.vault-internal:8200 -ca-path /etc/vault-tls/vault-tls/ca.crt"
```

## Expose Vault

```shell
oc get secret vault-tls -n vault -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/ca.crt
oc create route reencrypt --service vault-ui -n vault --port https --dest-ca-cert /tmp/ca.crt
```

## Testing vault

```shell
export VAULT_ADDR=https://$(oc get route vault-ui -n vault -o jsonpath='{.spec.host}')
export VAULT_TOKEN=${HA_VAULT_TOKEN}
vault status -tls-skip-verify
```

to access the vault ui browse here:

```shell
echo $VAULT_ADDR/ui
```


## Vault cert-manager integration

With this integration we enable the previously installed cert-manager to create certificates via vault.

### Prepare Kubernetes authentication

```shell
export VAULT_ADDR=https://$(oc get route vault-ui -n vault -o jsonpath='{.spec.host}')
export VAULT_TOKEN=$(oc get secret vault-init -n vault -o jsonpath='{.data.root_token}' | base64 -d)
vault auth enable -tls-skip-verify kubernetes
oc adm policy add-cluster-role-to-user system:auth-delegator -z default -n vault
export sa_secret_name=$(oc get sa default -n vault -o jsonpath='{.secrets[*].name}' | grep -o '\b\w*\-token-\w*\b')
oc get secret ${sa_secret_name} -n vault -o jsonpath='{.data.ca\.crt}' | base64 -d > /tmp/ca.crt
vault write -tls-skip-verify auth/kubernetes/config token_reviewer_jwt="$(oc serviceaccounts get-token default -n vault)" kubernetes_host=https://kubernetes.default.svc:443 kubernetes_ca_cert=@/tmp/ca.crt
vault write -tls-skip-verify auth/kubernetes/role/cert-manager bound_service_account_names=default bound_service_account_namespaces=vault policies=default,cert-manager
```

### Prepare vault pki

```shell
export VAULT_ADDR=https://$(oc get route vault-ui -n vault -o jsonpath='{.spec.host}')
export VAULT_TOKEN=$(oc get secret vault-init -n vault -o jsonpath='{.data.root_token}' | base64 -d)
vault secrets enable -tls-skip-verify pki
vault write -tls-skip-verify pki/root/generate/internal common_name=cert-manager.cluster.local
vault write -tls-skip-verify pki/config/urls issuing_certificates="http://vault.vault.svc:8200/v1/pki/ca" crl_distribution_points="http://vault.vault.svc:8200/v1/pki/crl"
vault write -tls-skip-verify pki/roles/cert-manager allowed_domains=svc,svc.cluster.local allow_subdomains=true allow_localhost=false
vault policy write -tls-skip-verify cert-manager ./cert-manager-policy.hcl
```

### Prepare cert-manager Cluster Issuer

```shell
export vault_ca=$(oc get secret vault-tls -n vault -o jsonpath='{.data.ca\.crt}' | base64 -d | sed 's/^/      /')
export vault_ca=$(oc get secret vault-tls -n vault -o jsonpath='{.data.ca\.crt}')
export sa_secret_name=$(oc get sa default -n vault -o jsonpath='{.secrets[*].name}' | grep -o '\b\w*\-token-\w*\b')
envsubst < vault-issuer.yaml | oc apply -f - -n vault
```

### Create a sample cert

```shell
oc apply -f ./sample-vault-cert.yaml -n vault
```

# Install Vault

```shell
git clone https://github.com/hashicorp/vault-helm
oc new-project vault
oc adm policy add-scc-to-user anyuid -z vault -n vault
helm template vault ./vault-helm -n vault -f ./values.yaml | oc apply -f - -n vault
oc create route edge vault-ui --service vault-ui -n vault
```

## Initialize Vault

this is a good tutorial: https://learn.hashicorp.com/vault/operations/raft-storage

```shell
INIT_RESPONSE=$(oc exec vault-0 -n vault -- vault operator init -key-shares=1 -key-threshold=1)

UNSEAL_KEY=$(echo "$INIT_RESPONSE" | jq -r .unseal_keys_b64[0])
VAULT_TOKEN=$(echo "$INIT_RESPONSE" | jq -r .root_token)

echo "$UNSEAL_KEY" > /tmp/unseal_key-vault_1
echo "$VAULT_TOKEN" > /tmp/root_token-vault_1

oc exec vault-0 -n vault -- operator unseal "$UNSEAL_KEY"
oc exec vault-0 -n vault -- login "$VAULT_TOKEN"

oc exec vault-0 -n vault -- secrets enable transit
oc exec vault-0 -n vault -- write -f transit/keys/unseal_key
```

```shell
INIT_RESPONSE2=$(oc exec vault-1 -n vault -- operator init -format=json -recovery-shares 1 -recovery-threshold 1)

RECOVERY_KEY2=$(echo "$INIT_RESPONSE2" | jq -r .recovery_keys_b64[0])
VAULT_TOKEN2=$(echo "$INIT_RESPONSE2" | jq -r .root_token)

echo "$RECOVERY_KEY2" > /tmp/recovery_key-vault_2
echo "$VAULT_TOKEN2" > /tmp/root_token-vault_2

oc exec vault-1 -n vault -- login "$VAULT_TOKEN2"
oc exec vault-1 -n vault -- secrets enable -path=kv kv-v2

oc exec vault-1  kv put kv/apikey webapp=ABB39KKPTWOR832JGNLS02
oc exec vault-1  kv get kv/apikey
```

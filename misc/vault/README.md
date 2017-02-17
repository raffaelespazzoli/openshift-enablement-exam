you need vault CLI installed on your machine

create a new project
```
oc new-project vault-controller
```
If you have 3.4 or later skip this step (we are going to use this feature https://docs.openshift.com/container-platform/3.4/dev_guide/secrets.html#service-serving-certificate-secrets).

Generate a self-signed certificate.

You can skip this step and bring your own otherwise-signed certificate
```
openssl req -new -x509 -days 365 -nodes -out vault.pem -keyout vault.key
oc create secret tls vault-cert --cert=vault.pem --key=vault.key
rm vault.key vault.pem 

```
Install vault
```
oc adm policy add-scc-to-user anyuid -z default
oc create configmap vault-config --from-file=vault-config=./vault-config.json
oc create -f vault.yaml
oc create route passthrough vault --port=8200 --service=vault
```
initialize vault
```
export VAULT_ADDR=https://`oc get route | grep -m1 vault | awk '{print $2}'`
vault init -tls-skip-verify -key-shares=1 -key-threshold=1
```
Save the generated key and token. 

Unseal Vault.
 
You have to repeat this step every time you start vault. 

Don't try to automate this step, this is manual by design. 

You can make the initial seal stronger by increasing the number of keys. 

We will assume that the KEYS environment variable contains the key necessary to unseal the vault and that ROOT_TOKEN contains the root token.

For example:
`export KEYS=6qvlf7Sdhq7JuKr5fuyAuBzSZq3FcOE8FCjf7b/5OcE=`
`export ROOT_TOKEN=9ca20590-d705-a5f2-635d-6329c342bc1d`
```
vault unseal -tls-skip-verify $KEYS
```
#configure vault (bootstrap flow)
```
vault auth -tls-skip-verify $ROOT_TOKEN
vault mount -tls-skip-verify -path=root-ca -max-lease-ttl=87600h pki
vault write -tls-skip-verify root-ca/root/generate/internal common_name="Root CA" ttl=87600h exclude_cn_from_sans=true
vault write -tls-skip-verify root-ca/config/urls issuing_certificates="http://vault:8200/v1/root-ca/ca" crl_distribution_points="http://vault:8200/v1/root-ca/crl"
vault mount -tls-skip-verify -path=intermediate-ca -max-lease-ttl=43800h pki
vault write -tls-skip-verify -field csr intermediate-ca/intermediate/generate/internal common_name="Intermediate CA" ttl=43800h exclude_cn_from_sans=true > intermediate.csr
vault write -tls-skip-verify -field=certificate root-ca/root/sign-intermediate csr=@intermediate.csr use_csr_values=true exclude_cn_from_sans=true > signed.crt
vault write -tls-skip-verify intermediate-ca/intermediate/set-signed certificate=@signed.crt
vault write -tls-skip-verify intermediate-ca/config/urls issuing_certificates="http://vault:8200/v1/intermediate-ca/ca" crl_distribution_points="http://vault:8200/v1/intermediate-ca/crl"
vault write -tls-skip-verify intermediate-ca/roles/kubernetes-vault allow_any_name=true max_ttl="24h"
rm intermediate.csr signed.crt
vault auth-enable -tls-skip-verify approle
vault write -tls-skip-verify auth/approle/role/sample-app secret_id_ttl=90s period=6h secret_id_num_uses=1
vault policy-write -tls-skip-verify kubernetes-vault policy.hcl
vault write -tls-skip-verify auth/token/roles/kubernetes-vault allowed_policies=kubernetes-vault period=6h
export VAULT_CONTROLLER_TOKEN=`vault token-create -tls-skip-verify -role=kubernetes-vault | grep token -m1 | awk '{print $2}'`
export ROLE_ID=`vault read -tls-skip-verify -field=role_id auth/approle/role/sample-app/role-id`
```
install vault-controller
```
oc policy add-role-to-user view -z default
oc process vault-controller-template.yaml -p VAULT_CONTROLLER_TOKEN=$VAULT_CONTROLLER_TOKEN | oc create -f -

```
deploy a sample app
```
oc new-project sample-app-vault
oc create -f sample-app.yaml
```

#Configure vault (kingsley flow)

deploy the vault controller
```
oc create secret generic vault-controller --from-literal vault-token=$ROOT_TOKEN
oc process -f vault-controller-template2.yaml | oc apply -f -
```
deploy the example
```
oc create -f vault-example-dc.yaml
```


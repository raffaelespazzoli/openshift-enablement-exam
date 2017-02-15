export VAULT_ADDR=`oc get route | grep -m1 vault | awk '{print $2}'`
vault auth vault-root-token
vault mount -path=root-ca -max-lease-ttl=87600h pki
vault write root-ca/root/generate/internal common_name="Root CA" ttl=87600h exclude_cn_from_sans=true
vault write root-ca/config/urls issuing_certificates="http://vault:8200/v1/root-ca/ca" crl_distribution_points="http://vault:8200/v1/root-ca/crl"
vault mount -path=intermediate-ca -max-lease-ttl=43800h pki
vault write -field csr intermediate-ca/intermediate/generate/internal common_name="Intermediate CA" ttl=43800h exclude_cn_from_sans=true > intermediate.csr
vault write -field=certificate root-ca/root/sign-intermediate csr=@intermediate.csr use_csr_values=true exclude_cn_from_sans=true > signed.crt
vault write intermediate-ca/intermediate/set-signed certificate=@signed.crt
vault write intermediate-ca/config/urls issuing_certificates="http://vault:8200/v1/intermediate-ca/ca" crl_distribution_points="http://vault:8200/v1/intermediate-ca/crl"
vault write intermediate-ca/roles/kubernetes-vault allow_any_name=true max_ttl="24h"
rm intermediate.csr signed.crt
vault auth-enable approle
vault write auth/approle/role/sample-app secret_id_ttl=90s period=6h secret_id_num_uses=1
vault policy-write kubernetes-vault policy.hcl
vault write auth/token/roles/kubernetes-vault allowed_policies=kubernetes-vault period=6h
vault token-create -role=kubernetes-vault
export ROLE_ID=`vault read -field=role_id auth/approle/role/sample-app/role-id`

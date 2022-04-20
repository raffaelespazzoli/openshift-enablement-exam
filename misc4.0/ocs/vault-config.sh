export VAULT_ADDR=https://vault.apps.control-cluster-raffa.demo.red-chesterfield.com
export VAULT_TOKEN=$(oc get secret vault-init -n vault -o jsonpath="{.data.root_token}" | base64 -d )

vault policy write ocs-cluster - << EOS
path "csi-secret/data/granular-kube-auth/*" {
  capabilities = ["create", "update", "delete", "read", "list"]
}
path "csi-secret/metadata/granular-kube-auth/*" {
  capabilities = ["read", "delete", "list"]
}

path "csi-secret/data/granular-token-auth/*" {
  capabilities = ["create", "update", "delete", "read", "list"]
}
path "csi-secret/metadata/granular-token-auth/*" {
  capabilities = ["read", "delete", "list"]
}

path "csi-secret/data/cluster-wide-token-auth/*" {
  capabilities = ["create", "update", "delete", "read", "list"]
}
path "csi-secret/metadata/cluster-wide-token-auth/*" {
  capabilities = ["read", "delete", "list"]
}

path "sys/mounts" {
  capabilities = ["read"]
}

EOS

# create a role
vault write "auth/kubernetes/role/csi-kubernetes" \
    bound_service_account_names="rbd-csi-nodeplugin,rbd-csi-provisioner,csi-rbdplugin,csi-rbdplugin-provisioner,rook-csi-rbd-provisioner-sa,rook-csi-rbd-plugin-sa" \
    bound_service_account_namespaces="openshift-storage" \
    policies="ocs-cluster"

vault secrets enable -path=csi-secret kv-v2    

vault secrets enable -path=myapp-dev kv-v2
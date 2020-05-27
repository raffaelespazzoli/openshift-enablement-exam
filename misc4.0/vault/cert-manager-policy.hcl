# add full access to the cert-manager cert issuer
path "pki/issue/cert-manager" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "pki/sign/cert-manager" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
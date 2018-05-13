```
oc new-project vault-operator
oc adm policy add-scc-to-user anyuid -z default
oc apply -f ./rbac.yaml
oc apply -f https://raw.githubusercontent.com/coreos/vault-operator/master/example/etcd_crds.yaml
oc apply -f https://raw.githubusercontent.com/coreos/vault-operator/master/example/etcd-operator-deploy.yaml
oc apply -f https://raw.githubusercontent.com/coreos/vault-operator/master/example/vault_crd.yaml
oc apply -f https://raw.githubusercontent.com/coreos/vault-operator/master/example/deployment.yaml
oc apply -f https://raw.githubusercontent.com/coreos/vault-operator/master/example/example_vault.yaml
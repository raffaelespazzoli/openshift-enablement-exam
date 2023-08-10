# Declarative ROSA

## Deploy Flux and the Terraform extension
```sh
flux install
oc adm policy add-scc-to-group nonroot-v2 system:serviceaccounts:flux-system -n flux-system
#oc apply -f https://raw.githubusercontent.com/weaveworks/tf-controller/main/docs/release.yaml
TF_CON_VER=v0.15.1
oc create -f https://github.com/weaveworks/tf-controller/releases/download/${TF_CON_VER}/tf-controller.crds.yaml
oc apply -f https://github.com/weaveworks/tf-controller/releases/download/${TF_CON_VER}/tf-controller.rbac.yaml
oc apply -f https://github.com/weaveworks/tf-controller/releases/download/${TF_CON_VER}/tf-controller.deployment.yaml
oc create sa tf-controller -n flux-system
```

## Deploy needed secrets

```sh
oc create secret generic ocm-token --from-literal=token=$(ocm token --refresh) -n flux-system
oc create secret generic aws-credentials --from-literal=AWS_ACCESS_KEY_ID=$(aws --profile rosa configure export-credentials | jq -r .AccessKeyId) --from-literal=AWS_SECRET_ACCESS_KEY=$(aws --profile rosa configure export-credentials | jq -r .SecretAccessKey) --from-literal=AWS_REGION=us-west-1 -n flux-system
```

# Deploy manifest to create a ROSA cluster

These manifest could exist in a gitops repo.

```sh
oc apply -f ./git-repository.yaml -n flux-system 
oc apply -f ./terraform-prereqs.yaml -n flux-system 
oc apply -f ./terraform-rosa.yaml -n flux-system
```
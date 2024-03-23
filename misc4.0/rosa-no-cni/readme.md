```sh
git clone https://github.com/openshift-cs/terraform-vpc-example
# edit sample.tfvars
terraform init
terraform plan -out rosa.tfplan -var-file=sample.tfvars
terraform apply rosa.tfplan
```

```sh
export region=us-west-2
rosa create oidc-config --region ${region}
rosa create account-roles --hosted-cp --region ${region}
rosa create operator-roles --prefix raffa-hpc --oidc-config-id 29chpakicmv3ha7ql91k3qhabn80nahl --hosted-cp --region ${region}
rosa create cluster --cluster-name=raffa-hpc --sts --mode=auto --hosted-cp --operator-roles-prefix raffa-hpc --oidc-config-id 29chpakicmv3ha7ql91k3qhabn80nahl --subnet-ids=subnet-001f732066cfba011,subnet-030a4ae7817a31b98,subnet-007918212ae3ba4bf,subnet-09882e18491d481bd,subnet-0b70a209da6ab3086,subnet-0f369f559889c0933 --region ${region} --billing-account=706529349667 --no-cni
```

```sh
rosa delete cluster --cluster raffa-hpc --watch --region=us-west-2
```

```sh
# change the geneve port to 60811
kubectl -n openshift-ovn-kubernetes delete DaemonSet ovnkube-node
oc apply -f calico/*.yaml
```
# Enabling GPU nodes

follow instructions here to download subscription certificate:
https://access.redhat.com/solutions/4908771

copy teh content to the local `./subscription` folder

## Create GPU-enabled nodes

```shell
  export cluster_name=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
  export region=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.aws.region}')
  export ami=$(oc get machineset -n openshift-machine-api -o jsonpath='{.items[0].spec.template.spec.providerSpec.value.ami.id}')
  export machine_type=ai-ml
  export instance_type=g3s.xlarge
  for z in a b c; do
    export zone=${region}${z}
    oc scale machineset -n openshift-machine-api $(envsubst < ./machineset.yaml | yq -r .metadata.name) --replicas 0 
    envsubst < ./machineset.yaml | oc apply -f -
  done
```

entitle the gpu nodes to rhel builds

```shell
unzip -o -d ./subscription ./subscription/consumer_export.zip 
export file=$(ls ./subscription/export/entitlement_certificates/*.pem)
sed  "s/BASE64_ENCODED_PEM_FILE/$(base64 -w0 ${file})/g" entitlement.yaml | oc apply -f -
```

## Deploy operators and policy

```shell
oc apply -f nfd-operator.yaml
oc apply -f gpu-operator.yaml
oc apply -f nfd-discovery.yaml -n openshift-operators
oc new-project gpu-operator-resources
oc apply -f cluster-policy.yaml -n gpu-operator-resources
```


https://gitlab.consulting.redhat.com/jhankes/gpu-cpu-benchmarks/-/blob/master/nvidia-disconnected/nvd-driver/Dockerfile.base

# Enabling GPU nodes

follow instructions here to download subscription certificate:
https://access.redhat.com/solutions/4908771

copy the content to the local `./subscription` folder

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
oc new-project nfd-operator
oc apply -f nfd-operator.yaml -n nfd-operator
oc new-project gpu-operator
oc apply -f gpu-operator.yaml -n gpu-operator
oc apply -f nfd-discovery.yaml -n nfd-operator
oc new-project gpu-operator-resources
oc apply -f cluster-policy.yaml -n gpu-operator-resources
```

## Test/View GPU utilization

```
for pod in $(oc get pods --selector app=nvidia-driver-daemonset -o jsonpath='{.items[*].metadata.name}'); do
  echo -e "\n=============================\n$pod\n=============================\n"
  oc exec $pod -- nvidia-smi
done
```

## Clean up

```
oc delete ClusterPolicy gpu-cluster-policy -n gpu-operator-resources
oc delete NodeFeatureDiscovery nfd-master-server -n openshift-operators

oc delete Subscription gpu-operator-certified -n openshift-operators
oc delete Subscription nfd -n openshift-operators

for z in a b c; do
    export zone=${region}${z}
    oc delete machineset ${cluster_name}-${machine_type}-${zone} -n openshift-machine-api
done  

# All nodes will reboot after deleting the following
oc delete MachineConfig rhel-entitlement

oc delete project gpu-operator-resources
```

https://gitlab.consulting.redhat.com/jhankes/gpu-cpu-benchmarks/-/blob/master/nvidia-disconnected/nvd-driver/Dockerfile.base

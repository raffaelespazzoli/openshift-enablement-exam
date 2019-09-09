make sure all machineset have at least one instance if needed:

```
for machineset in $(oc get machineset -n openshift-machine-api -o json | jq -r '.items[] | select (.spec.replicas==0) | .metadata.name'); do
  oc scale machineset $machineset --replicas=1 -n openshift-machine-api
done  
```


enable autoscaler

```
oc apply -f autoscaler.yaml
for machineset in $(oc get machineset -n openshift-machine-api -o json | jq -r '.items[] | select (.spec.replicas!=0) | .metadata.name'); do
  machineset=$machineset envsubst < machineset-autoscaler.yaml | oc apply -f - -n openshift-machine-api
done
```  
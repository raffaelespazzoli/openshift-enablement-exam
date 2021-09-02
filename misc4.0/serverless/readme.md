# Serverless Operator

## Install the Operator

```shell
oc create namespace openshift-serverless
oc label namespace openshift-serverless openshift.io/cluster-monitoring=true
oc apply -f operators.yaml -n openshift-serverless
```

## Install knative serving and eventing

```shell

oc apply -f knative-serving.yaml -n knative-serving

oc apply -f knative-eventing.yaml -n knative-eventing
```

# Serverless Operator

## Install the Operator

```shell
oc apply -f operators.yaml
```

## Install knative serving and eventing

```shell
oc new-project knative-serving
oc apply -f knative-serving.yaml -n knative-serving
oc new-project knative-eventing
oc apply -f knative-eventing.yaml -n knative-eventing
```

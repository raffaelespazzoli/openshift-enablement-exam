
```shell
oc apply -f operator.yaml
oc new-project kubeflow
oc apply -f kubeflow.yaml -n kubeflow
```

deploy a seldon modes

```shell
oc new-project seldon
oc apply -f ./iris-seldon.yaml -n seldon
```

# SM + GRPC

```shell
oc apply -f operators.yaml
oc new-project istio-system
oc apply -f control_plane.yaml 
```

```shell
oc new-project test-grpc
oc apply -f servicemember.yaml -n test-grpc
```

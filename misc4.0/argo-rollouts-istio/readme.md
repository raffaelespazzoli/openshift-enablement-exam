
```shell
oc new-project argo-rollout-test
oc adm policy add-scc-to-user anyuid -z default -n argo-rollout-test
oc apply -f service-mesh-member.yaml -n argo-rollout-test
oc apply -f service.yaml -n argo-rollout-test
oc apply -f virtual-service.yaml -n argo-rollout-test
oc apply -f deployment.yaml -n argo-rollout-test
oc apply -f argo-rollout.yaml -n argo-rollout-test
```

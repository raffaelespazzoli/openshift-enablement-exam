# Progressive Delivery

## Deploy ServiceMesh

```shell
oc apply -f ./servicemesh/operators.yaml
oc new-project istio-system
oc apply -f ./servicemesh/user-workload-monitoring.yaml
```

## Deploy GatewayAPI 

following these instructions: https://github.com/gcs278/network-edge-tools/blob/enhanced-dev-preview/docs/blogs/EnhancedDevPreviewGatewayAPI/GettingStarted.md

```sh
oc adm policy add-cluster-role-to-user cluster-admin -z ingress-operator -n openshift-ingress-operator
oc patch featuregates/cluster --type=merge --patch='{"spec":{"featureSet":"CustomNoUpgrade","customNoUpgrade":{"enabled":["GatewayAPI"]}}}'
oc apply -f ./gateway-api/gateway-class.yaml
export DOMAIN=$(oc get ingresses.config/cluster -o jsonpath={.spec.domain})
envsubst < ./gateway-api/gateway.yaml | oc apply -f - -n openshift-ingress
oc apply -f ./gateway-api/pod-monitor.yaml -n openshift-ingress
```



## Deploy OpenShift Gitops

```sh
oc apply -f ./gitops/operator.yaml
oc apply -f ./gitops/argocd.yaml
```

## Preparing for Progressive delivery

### Deploy test application
```shell
oc new-project bookinfo
oc label namespace bookinfo istio-injection=enabled
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/istio/maistra-2.4/samples/bookinfo/platform/kube/bookinfo.yaml
```

we are now going to delete the reviews deployments, which feature different versions (v1, v2, v3) and refactor this implementation with roolouts. At the time of the writing, the three images were respectively:
- quay.io/maistra/examples-bookinfo-reviews-v1:2.4.0
- quay.io/maistra/examples-bookinfo-reviews-v2:2.4.0
- quay.io/maistra/examples-bookinfo-reviews-v3:2.4.0 

In the spirit of the original book info demo, we will proceed with two canary rollouts, going from v1 to v3.
The following commands prepare the environment.

```sh
oc delete deployment reviews-v1 -n bookinfo
oc delete deployment reviews-v2 -n bookinfo
oc delete deployment reviews-v3 -n bookinfo
oc apply -f ./rollouts/rollout-controller.yaml -n bookinfo
oc apply -f ./rollouts/gateway-api-plugin-configmap.yaml -n bookinfo
oc apply -f ./rollouts/rollout-sa-secret.yaml -n bookinfo
oc apply -f ./rollouts/role-binding.yaml -n bookinfo
oc apply -f ./rollouts/deployment.yaml -n bookinfo
oc apply -f ./rollouts/reviews-stable-service.yaml -n bookinfo
oc apply -f ./rollouts/reviews-canary-service.yaml -n bookinfo
oc apply -f ./rollouts/reviews-service.yaml -n bookinfo
oc apply -f ./rollouts/http-route.yaml -n bookinfo
oc apply -f ./rollouts/analysis-template.yaml -n bookinfo
oc apply -f ./rollouts/rollout.yaml -n bookinfo
```

first rollout:

```sh
oc argo rollouts set image reviews reviews=quay.io/maistra/examples-bookinfo-reviews-v2:2.4.0
oc argo rollouts get rollout reviews --watch -n bookinfo
```

second rollout

```sh
oc argo rollouts set image reviews reviews=quay.io/maistra/examples-bookinfo-reviews-v3:2.4.0
oc argo rollouts get rollout reviews --watch -n bookinfo
```

## Install redis via helm

for details see [here](https://github.com/bitnami/charts/tree/master/bitnami/redis-cluster)

```shell
helm repo add bitnami https://charts.bitnami.com/bitnami
oc new-project redis
export uid=$(oc get project redis -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'|sed 's/\/.*//')
helm upgrade -i redis bitnami/redis-cluster -n redis --values values-production.yaml --set containerSecurityContext.runAsUser=${uid} --set containerSecurityContext.fsGroup=${uid} --set podSecurityContext.runAsUser=${uid} --set podSecurityContext.fsGroup=${uid}
```

### Test connectivity

```shell
export REDIS_PASSWORD=$(kubectl get secret -n redis redis-redis-cluster -o jsonpath="{.data.redis-password}" | base64 --decode)
oc exec -n redis redis-redis-cluster-0 -- redis-cli -c -h redis-redis-cluster -a $REDIS_PASSWORD ping
```

## Operator based installation

### Installing the operator

```shell
oc new-project redis
oc apply -f https://raw.githubusercontent.com/RedisLabs/redis-enterprise-k8s-docs/master/openshift/scc.yaml
oc apply -f operator.yaml -n redis
```

### Installing the cluster

```shell
oc apply -f redis.yaml -n redis
oc create route passthrough rec-ui --service rec-ui
export admin_password=$(oc get secret rec -n redis -o jsonpath='{.data.password}' | base64 -d)
export admin_username=$(oc get secret rec -n redis -o jsonpath='{.data.username}' | base64 -d)
export redis_ui=$(oc get route rec-ui -n redis -o jsonpath='{.spec.hostname}')
#poiint your browser at
echo $redis_ui  
echo ${admin_username}/${admin_password}
```

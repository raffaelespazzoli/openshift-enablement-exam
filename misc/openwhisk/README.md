# Install the command line

```
curl -L https://github.com/apache/incubator-openwhisk-cli/releases/download/latest/OpenWhisk_CLI-latest-linux-amd64.tgz | tar -zxvf - -C /tmp
sudo cp /tmp/wsk /usr/bin
```

# Deploy openwhisk

## Preparation

```
oc new-project openwhisk
oc apply -f https://raw.githubusercontent.com/apache/incubator-openwhisk-deploy-kube/master/kubernetes/cluster-setup/services.yml
oc create cm whisk.config --from-env-file=./incubator-openwhisk-deploy-kube/kubernetes/cluster-setup/config.env
oc create cm whisk.runtimes --from-file=./incubator-openwhisk-deploy-kube/kubernetes/cluster-setup/runtimes.json
oc create cm whisk.limits --from-env-file=./incubator-openwhisk-deploy-kube/kubernetes/cluster-setup/limits.env
oc create secret generic whisk.auth --from-file=system=./incubator-openwhisk-deploy-kube/kubernetes/cluster-setup/auth.whisk.system --from-file=guest=./incubator-openwhisk-deploy-kube/kubernetes/cluster-setup/auth.guest
```

## Deploy CouchDB

```
oc create secret generic db.auth --from-literal=db_username=whisk_admin --from-literal=db_password=some_passw0rd
oc create configmap db.config --from-literal=db_protocol=http --from-literal=db_provider=CouchDB --from-literal=db_whisk_activations=test_activations --from-literal=db_whisk_actions=test_whisks --from-literal=db_whisk_auths=test_subjects --from-literal=db_prefix=test
oc apply -f https://raw.githubusercontent.com/apache/incubator-openwhisk-deploy-kube/master/kubernetes/couchdb/couchdb.yml
oc set volumes deployment/couchdb -t emptyDir -m /openwhisk --add
```

## Deploy remaining components

### Apigateway

```
oc apply -f https://raw.githubusercontent.com/apache/incubator-openwhisk-deploy-kube/master/kubernetes/apigateway/apigateway.yml
```

### Zookeeper
```
oc apply -f https://raw.githubusercontent.com/apache/incubator-openwhisk-deploy-kube/master/kubernetes/zookeeper/zookeeper.yml
```
### Kafka
```
oc apply -f https://raw.githubusercontent.com/apache/incubator-openwhisk-deploy-kube/master/kubernetes/kafka/kafka.yml
```
### Controller
```
oc create cm controller.config --from-env-file=./incubator-openwhisk-deploy-kube/kubernetes/controller/controller.env
oc apply -f https://raw.githubusercontent.com/apache/incubator-openwhisk-deploy-kube/master/kubernetes/controller/controller.yml
```
### Invoker
```
oc create cm invoker.config --from-env-file=./incubator-openwhisk-deploy-kube/kubernetes/invoker/invoker.env
oc apply -f https://raw.githubusercontent.com/apache/incubator-openwhisk-deploy-kube/master/kubernetes/invoker/invoker.yml
```
### Nignix
```
oc create configmap nginx --from-file=./incubator-openwhisk-deploy-kube/kubernetes/nginx/nginx.conf
oc apply -f https://raw.githubusercontent.com/apache/incubator-openwhisk-deploy-kube/master/kubernetes/nginx/nginx.yml
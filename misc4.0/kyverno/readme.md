# Installation

```shell
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm upgrade kyverno kyverno/kyverno -i -n kyverno --create-namespace --set replicaCount=3
oc adm policy add-cluster-role-to-user cluster-admin -z kyverno -n kyverno
```

test scenario

```shell
oc apply -f topic-cluster-policy.yaml
oc new-project my-kafka
oc apply -f kafka.yaml -n my-kafka
oc new-project my-tenant
oc label namespace my-tenant tenant=true
oc apply -f topic.yaml -n my-tenant
oc apply -f non-compliant-topic.yaml -n my-tenant
```

pod label

```sh
oc new-project my-tenant
oc apply -f ./policy.yaml -n my-tenant
oc new-app centos/ruby-25-centos7~https://github.com/sclorg/ruby-ex.git -l preexisting=true -n my-tenant
```

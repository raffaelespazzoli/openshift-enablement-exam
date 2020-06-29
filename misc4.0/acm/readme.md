# Installing ACM

```shell
oc new-project open-cluster-management
oc apply -f operator.yaml -n open-cluster-management
oc create secret docker-registry acm-pull-secret --docker-server=registry.access.redhat.com/rhacm1-tech-preview --docker-username=<docker_username> --docker-password=<docker_password> -n open-cluster-management
oc apply -f acm.yaml -n open-cluster-management
#run this to work around: https://bugzilla.redhat.com/show_bug.cgi?id=1847540
oc annotate etcdcluster etcd-cluster etcd.database.coreos.com/scope=clusterwide -n open-cluster-management
```

## Create three clusters

Variable preparation

replace where appropriately with your values.

```shell
export ssh_key=$(cat ~/.ssh/ocp_rsa | sed 's/^/  /')
export ssh_pub_key=$(cat ~/.ssh/ocp_rsa.pub)
export pull_secret=$(cat ~/git/openshift-enablement-exam/4.0/config/pullsecret.json)
export aws_id=$(cat ~/.aws/credentials | grep aws_access_key_id | cut -d'=' -f 2)
export aws_key=$(cat ~/.aws/credentials | grep aws_secret_access_key | cut -d'=' -f 2)
```

create clusters

```shell
export region="us-east-1"
envsubst < ./cluster-values.yaml > /tmp/values.yaml
helm upgrade raffa1 ./acm-aws-cluster --create-namespace -i -n raffa1  -f /tmp/values.yaml

export region="us-east-2"
envsubst < ./cluster-values.yaml > /tmp/values.yaml
helm upgrade raffa2 ./acm-aws-cluster --create-namespace -i -n raffa2  -f /tmp/values.yaml

export region="us-west-1"
envsubst < ./cluster-values.yaml > /tmp/values.yaml
helm upgrade raffa3 ./acm-aws-cluster --create-namespace -i -n raffa3  -f /tmp/values.yaml
```

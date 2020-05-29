# Installing ACM

```shell
oc new-project open-cluster-management
oc apply -f operator.yaml -n open-cluster-management
oc create secret docker-registry acm-pull-secret --docker-server=registry.access.redhat.com/rhacm1-tech-preview --docker-username=<docker_username> --docker-password=<docker_password> -n open-cluster-management
oc apply -f acm.yaml -n open-cluster-management
```

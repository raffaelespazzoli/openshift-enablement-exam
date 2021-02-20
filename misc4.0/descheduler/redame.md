# Intsall descheduler

```shell
oc adm new-project openshift-kube-descheduler-operator
oc apply -f ./operator.yaml -n openshift-kube-descheduler-operator
oc apply -f ./descheduler-config.yaml -n openshift-kube-descheduler-operator
```

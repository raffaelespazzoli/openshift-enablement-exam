# Installing istio on openshift

download the latest version
```
curl -L https://git.io/getIstio | sh -
```

create a new project

```
oc new-project istio
```
set up service accounts permissions
```
oc apply -f istio-0.1.6/install/kubernetes/istio-rbac-beta.yaml
oc apply -f istio-0.1.6/install/kubernetes/istio-auth-with-cluster-ca.yaml
```

openshift way

```
oc create sa istio-pilot-service-account
oc create sa istio-ingress-service-account
oc adm policy add-cluster-role-to-user cluster-admin -z istio-pilot-service-account


oc apply -f istio-0.1.6/install/kubernetes/istio.yaml 
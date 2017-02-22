#install the client

```
curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | sh -
```

#install tiller

```
oc new-project tiller
helm init --tiller-namespace tiller
#oc expose svc tiller-deploy
#export HELM_HOST=`oc get route | grep tiller-deploy | awk '{print $2}'`:80
oc adm policy add-cluster-role-to-user edit system:serviceaccount:tiller:default

```

#using helm with port forwarding
tiller doesn't work through the proxy because http2 is not currently supported.
```
oc port-forward `oc get pods | grep tiller-deploy | awk '{print $1}'` 44134:44134 &
export HELM_HOST=localhost:44134
helm version
```

#testing helm
tiller is not able to create openshift project so you have to create them for it
```
oc new-project tiller-mysql
helm repo update
helm install --namespace tiller-mysql stable/mysql
```
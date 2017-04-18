# Install Prometheus

```
oc new-project prometheus
oc create sa prometheus
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:prometheus:prometheus
oc create -f prometheus.yaml
oc expose svc prometheus
```

# install kube-ops-view
https://github.com/hjacobs/kube-ops-view

```
git clone https://github.com/hjacobs/kube-ops-view
oc new-project ops-view
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:ops-view:kube-ops-view
cd deploy
oc apply -f .
oc expose svc kube-ops-view
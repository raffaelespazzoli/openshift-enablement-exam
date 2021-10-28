```
git clone https://github.com/chubaofs/chubaofs-helm
cd chubaofs-helm/
cp ~/.kube/config chubaofs/config/kubeconfig
oc new-project chubaofs
helm upgrade chubaofs ./chubaofs -f ../values.yaml -n chubaofs -i --create-namespace
```
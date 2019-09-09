
```shell
oc new-project argocd
oc apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
oc create route passthrough --service argocd-server -n argocd --port=https
```
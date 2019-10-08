
```shell
oc new-project argocd
oc apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
oc create route passthrough argocd-server --service argocd-server -n argocd --port=https
export password=$(oc get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2)
export route=$(oc get route argocd-server -n argocd -o jsonpath='{.spec.host}')
argocd login $route --username=admin --password=$password
oc apply -f application-test.yaml 
```
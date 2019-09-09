```shell
oc new-project flux
oc apply -f https://raw.githubusercontent.com/fluxcd/flux/helm-0.10.1/deploy-helm/flux-helm-release-crd.yaml
helm repo add fluxcd https://charts.fluxcd.io
helm repo update
export flux_chart_version=$(helm search fluxcd/flux | grep fluxcd/flux | awk '{print $2}')
helm fetch fluxcd/flux --version ${flux_chart_version}
helm template flux-${flux_chart_version}.tgz --namespace flux --set helmOperator.create=true --set helmOperator.createCRD=false --set git.url=git@github.com:raffaelespazzoli/flux-get-started | oc apply -f - -n flux
rm flux-${flux_chart_version}.tgz
```
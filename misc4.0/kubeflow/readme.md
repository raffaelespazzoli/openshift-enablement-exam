# Kubeflow

This is a customized version of kubeflow from the official kubeflow for openshift release.
It assumes ServiceMesh 2.0.2 is already installed.

```shell
oc new-project kubeflow
oc label namespace kubeflow  control-plane=kubeflow katib-metricscollector-injection=enabled
oc apply -f service-mesh-member.yaml -n kubeflow
kustomize build ./kustomize/openshift-scc | oc apply -f -
kustomize build ./kustomize/istio | oc apply -f -
kustomize build ./kustomize/argo/overlays/istio | oc apply -f -
kustomize build ./kustomize/centraldashboard/overlays/istio | oc apply -f -
kustomize build ./kustomize/centraldashboard/overlays/istio | oc apply -f -
kustomize build ./jupyter-web-app | oc apply -f -
kustomize build ./kustomize/metadata/overlays/istio | oc apply -f -
kustomize build ./kustomize/metadata/overlays/db | oc apply -f -
kustomize build ./kustomize/metadata/overlays/openshift | oc apply -f -
kustomize build ./metadata | oc apply -f -

```

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
kustomize build ./kustomize/jupyter-web-app/overlays/istio | oc apply -f -
kustomize build ./kustomize/jupyter-web-app/overlays/openshift | oc apply -f -
kustomize build ./kustomize/metadata/overlays/istio | oc apply -f -
kustomize build ./kustomize/metadata/overlays/db | oc apply -f -
kustomize build ./kustomize/metadata/overlays/openshift | oc apply -f -
kustomize build ./kustomize/notebook-controller/overlays/istio | oc apply -f -
kustomize build ./kustomize/notebook-controller/overlays/openshift | oc apply -f -
kustomize build ./kustomize/pytorch-job-crds | oc apply -f -
kustomize build ./kustomize/pytorch-operator | oc apply -f -
kustomize build ./kustomize/tensorboard/overlays/istio | oc apply -f -
kustomize build ./kustomize/tf-job-crds | oc apply -f -
kustomize build ./kustomize/tf-job-operator | oc apply -f -
kustomize build ./kustomize/katib-crds | oc apply -f -
kustomize build ./kustomize/katib-controller/overlays/istio | oc apply -f - * (wrong webhook)
kustomize build ./kustomize/api-service | oc apply -f -
kustomize build ./kustomize/minio/overlays/openshift | oc apply -f -
kustomize build ./kustomize/mysql | oc apply -f -
kustomize build ./kustomize/persistent-agent | oc apply -f -
kustomize build ./kustomize/pipelines-runner | oc apply -f -
kustomize build ./kustomize/pipelines-ui/overlays/istio | oc apply -f -
kustomize build ./kustomize/pipelines-viewer | oc apply -f -
kustomize build ./kustomize/scheduledworkflow | oc apply -f -
kustomize build ./kustomize/pipeline-visualization-service | oc apply -f -
kustomize build ./kustomize/profiles/overlays/istio | oc apply -f -
kustomize build ./kustomize/profiles/overlays/openshift | oc apply -f -
kustomize build ./kustomize/seldon-core-operator/overlays/openshift | oc apply -f -
```

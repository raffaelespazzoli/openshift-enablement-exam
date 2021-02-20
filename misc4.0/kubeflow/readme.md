# Kubeflow

This is a customized version of kubeflow from the official kubeflow for openshift release.
It assumes ServiceMesh 2.0.2 is already installed.

```shell
oc new-project kubeflow
oc label namespace kubeflow  control-plane=kubeflow katib-metricscollector-injection=enabled
oc apply -f service-mesh-member.yaml -n kubeflow
kustomize build . | oc apply -f -
```

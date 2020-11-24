# OpenShift Pipelines

```shell
oc apply -f ./operator.yaml
```

## Deploy buildpack pipeline

```shell
export namespace=pipelines-tutorial
oc apply -f ./buildpackpipeline/buildpack-pipeline.yaml -n ${namespace}
```
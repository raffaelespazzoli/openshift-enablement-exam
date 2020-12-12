# OpenShift Pipelines

```shell
oc apply -f ./operator.yaml
```

## Deploy buildpack pipeline

```shell
export namespace=pipelines-tutorial
oc apply -f https://raw.githubusercontent.com/tektoncd/catalog/master/task/maven/0.2/maven.yaml -n ${namespace}
oc apply -f ./buildpackpipeline/buildpack-pipeline.yaml -n ${namespace}
```
conversion notes:

```shell
operator-sdk init --project-version="3-alpha" --owner "Red Hat Community of Practice" --domain redhat.io --repo github.com/redhat-cop/must-gather-operator --plugins "go.kubebuilder.io/v2" --plugins "go.kubebuilder.io/v3" --project-name must-gather-operator
```

copy .github
copy helm chart stuff in make

for every resource

```shell
operator-sdk create api --group=redhatcop --version=v1alpha1 --kind=MustGather --resource --controller
```

add to git ignore

copy config/operatothub

add readme and other docs

modify readme with deployment and local development sections

create the png from operatorhub

copy old types in new types

copy old controllers in new controllers 

fix the watchers

modify main to use configmap for leader election

fix compilation issues

fix controller permissions

copy local development

copy templates if needed

copy and rename helmcharts

fix docker file if needed
add registry.access.redhat.com/ubi8/ubi-minimal

remove permissions for auth_proxy

check if container needs arguments (must be put also in helm chart)

ensure watches are correctly initialized

test with run local

remove run_as security context

add existing tests

generate bundle

add crd samples

test deployment via OLM

add badges

bump to golang 1.15
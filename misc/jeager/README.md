simple
```
oc process -f https://raw.githubusercontent.com/jaegertracing/jaeger-openshift/master/all-in-one/jaeger-all-in-one-template.yml | oc create -f -
```
production ready
```
oc new-project jaeger-infra
oc process -f https://raw.githubusercontent.com/jaegertracing/jaeger-openshift/master/production/jaeger-production-template.yml | oc create -n jaeger-infra -f -
```
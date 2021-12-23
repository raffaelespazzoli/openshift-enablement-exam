# Contour

Install

Operator based

```shell
oc apply -f ./crds.yaml
oc apply -f ./operator.yaml
oc apply -f ./simple-gateway.yaml
oc adm policy add-scc-to-user nonroot -z contour -n projectcontour
oc adm policy add-scc-to-user nonroot -z contour-certgen -n projectcontour
oc apply -f ./rbac.yaml -n projectcontour # workaround to: https://github.com/projectcontour/contour-operator/issues/465
```

test:

```shell
oc apply -f ./httproute.yaml -n projectcontour
oc apply -f ./kuard.yaml -n projectcontour
```

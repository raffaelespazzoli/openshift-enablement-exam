# Contour

Install

```shell
helm repo add bitnami https://charts.bitnami.com/bitnami
helm upgrade contour bitnami/contour -i --create-namespace -n contour
```

Install Gaetway API

```shell
oc new-project projectcontour
oc adm policy add-scc-to-user anyuid -z contour -n projectcontour
oc adm policy add-scc-to-user hostnetwork -z envoy -n projectcontour
kubectl apply -f https://projectcontour.io/quickstart/contour-gateway.yaml
```

Operator based

```shell
kubectl apply -f https://projectcontour.io/quickstart/operator.yaml
kubectl apply -f https://projectcontour.io/quickstart/gateway.yaml
oc adm policy add-scc-to-user anyuid -z contour -n projectcontour
kubectl apply -f https://projectcontour.io/quickstart/kuard.yaml
```

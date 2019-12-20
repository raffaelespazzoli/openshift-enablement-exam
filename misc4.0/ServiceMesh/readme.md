```shell
oc new-project istio-system
oc apply -f operators.yaml
oc apply -f control_plane.yaml
```

Testing:
```shell
oc new-project bookinfo
#oc -n istio-system patch --type='json' smmr default -p '[{"op": "add", "path": "/spec/members", "value":["'"bookinfo"'"]}]'
oc apply -f servicememberroll.yaml -n istio-system
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/bookinfo/maistra-1.0/bookinfo.yaml
oc apply -n bookinfo -f https://raw.githubusercontent.com/Maistra/bookinfo/maistra-1.0/bookinfo-gateway.yaml
export istio_gateway_url=$(oc get route istio-ingressgateway -n istio-system -o jsonpath='{.spec.host}')
curl -k https://$istio_gateway_url/productpage
```

```shell
oc new-project spire
oc apply -f https://raw.githubusercontent.com/spiffe/spiffe-csi/main/example/config/spiffe-csi-driver.yaml
oc adm policy add-scc-to-user anyuid -z spire-server -n spire
oc adm policy add-scc-to-user privileged -z spire-agent -n spire
kubectl apply \
    -f https://raw.githubusercontent.com/spiffe/spire-tutorials/main/k8s/quickstart/server-account.yaml \
    -f https://raw.githubusercontent.com/spiffe/spire-tutorials/main/k8s/quickstart/spire-bundle-configmap.yaml \
    -f https://raw.githubusercontent.com/spiffe/spire-tutorials/main/k8s/quickstart/server-cluster-role.yaml

kubectl apply \
    -f https://raw.githubusercontent.com/spiffe/spire-tutorials/main/k8s/quickstart/server-configmap.yaml \
    -f https://raw.githubusercontent.com/spiffe/spire-tutorials/main/k8s/quickstart/server-statefulset.yaml \
    -f https://raw.githubusercontent.com/spiffe/spire-tutorials/main/k8s/quickstart/server-service.yaml

kubectl apply \
    -f https://raw.githubusercontent.com/spiffe/spire-tutorials/main/k8s/quickstart/agent-account.yaml \
    -f https://raw.githubusercontent.com/spiffe/spire-tutorials/main/k8s/quickstart/agent-cluster-role.yaml

kubectl apply \
    -f https://raw.githubusercontent.com/spiffe/spire-tutorials/main/k8s/quickstart/agent-configmap.yaml \
    -f ./spire-agent.yaml   

    
kubectl exec -n spire spire-server-0 --     /opt/spire/bin/spire-server entry create     -spiffeID spiffe://example.org/ns/spire/sa/spire-agent     -selector k8s_sat:cluster:demo-cluster     -selector k8s_sat:agent_ns:spire     -selector k8s_sat:agent_sa:spire-agent     -node         

```

test:
```shell
oc new-project test-spire
kubectl exec -n spire spire-server-0 --     /opt/spire/bin/spire-server entry create     -spiffeID spiffe://example.org/ns/test-spire/sa/default     -parentID spiffe://example.org/ns/spire/sa/spire-agent     -selector k8s:ns:test-spire     -selector k8s:sa:default
oc apply -n test-spire -f ./busybox.yaml
```
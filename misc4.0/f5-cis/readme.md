configure the f5 device 

```shell
modify auth password admin
```

log to the console
provision the GTM daemon
install the as3 rpm (https://clouddocs.f5.com/products/extensions/f5-appsvcs-extension/latest/userguide/installation.html) f5-appsvcs-3.33.0-4.noarch.rpm

if using OCP SDN create the vxlan config (https://clouddocs.f5.com/containers/latest/userguide/cis-installation.html#creating-vxlan-tunnels-on-openshift-cluster)
else look for the appropriate way to create the vxlan config in the docs

add the following security groups to the OCP nodes:
Inbound UDP 4789, 9000-9999, 31111

```shell
create net tunnels vxlan vxlan-mp flooding-type multipoint
create net tunnels tunnel openshift_vxlan key 0 profile vxlan-mp local-address <f5 device ip>
create net self <ip in the node-assigned cidr, check because ocp can change it>/14 allow-service all vlan openshift_vxlan
create auth partition ocp
oc apply -f ./host-subnet.yaml
```

```shell
oc new-project f5cis
kubectl create secret generic bigip-login -n f5cis --from-literal=username=admin --from-literal=password=<password>
helm repo add f5-stable https://f5networks.github.io/charts/stable
oc adm policy add-scc-to-user anyuid -z k8s-bigip-ctlr -n f5cis
oc apply -f cluster-role.yaml 
oc adm policy add-cluster-role-to-user f5cis-f5-bigip-ctlr-manual -z k8s-bigip-ctlr -n f5cis
helm upgrade f5cis f5-stable/f5-bigip-ctlr -i --create-namespace -n f5cis -f values.yaml
```

test GTM

```shell
oc apply -f ./virtual-server.yaml -n f5cis
oc apply -f ./external-dns.yaml -n f5cis
```

GTM
see also https://clouddocs.f5.com/training/community/dns/html/class1/module2/lab1.html

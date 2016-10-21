#egress test

create a project
```
oc new-project egress-test
```
create the test app
```
oc new-app https://github.com/raffaelespazzoli/openshift-enablement-exam --context-dir=misc/egress --strategy=docker --name=egress-test -l app=egress-test -e HOST=egress-svc -n egress-test
```
patch the new service to become be of loadbalancer type
```
oc patch svc egress-test -p '
"spec": {
  "type": "LoadBalancer"
  }'
```
this is all I need to do for ingress because I'm running on a cloud provider.
if you were on premise, would have to:

1. inspect the external ip that was assigned to you and configure a routing rule so that ip is served by one of the cluster nodes
2. assign a name to that ip in your dns.
3. if you want HA, you can use ip failover pods. follow this [instructions](https://docs.openshift.com/container-platform/3.3/admin_guide/high_availability.html#ip-failover) replacing the IP with the one that was assigned to your service.


create the egress pod
```
oc adm policy add-scc-to-user privileged system:serviceaccount:egress-test:default
BASTION_IP=`gcloud compute addresses list | grep ose-bastion | awk '{print $3}'`
oc process -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/egress/egress.yaml -v EGRESS_SOURCE=10.128.0.12,EGRESS_GATEWAY=`ssh $BASTION_IP /usr/sbin/ip route show 0.0.0.0/0 | awk '{print $3}'`,EGRESS_DESTINATION=`oc get service | grep egress-test | awk '{print $3}'` | oc create -f -
```




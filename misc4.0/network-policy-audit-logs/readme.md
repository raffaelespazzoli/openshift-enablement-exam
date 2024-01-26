```sh
oc patch network.operator.openshift.io cluster -p '{"spec": {"defaultNetwork": {"ovnKubernetesConfig": {"policyAuditConfig": {"destination": "udp:rsyslog-service.rsyslogd.svc.cluster.local:514","maxFileSize": 50,"rateLimit": 20,"syslogFacility": "local0"}}}}}' --type merge
oc new-project rsyslogd
oc adm policy add-scc-to-user anyuid -z default -n rsyslogd
oc apply -f rsyslogd-deployment.yaml -n rsyslogd
```

verify

```sh
oc apply -f namespace.yaml
#this will prevent traffic to the reviews pods
oc apply -f network-policy.yaml -n verify-audit-logging
#oc apply -f pods.yaml -n verify-audit-logging
oc apply -f bookinfo.yaml -n verify-audit-logging
oc apply -f egress-firewall.yaml -n verify-audit-logging
```

see audit logs

```sh
for pod in $(oc get pods -n openshift-ovn-kubernetes -l app=ovnkube-node --no-headers=true | awk '{ print $1 }') ; do
    oc exec -it $pod -n openshift-ovn-kubernetes -- tail -4 /var/log/ovn/acl-audit-log.log
done
```
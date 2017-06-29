# deploy metric in cdk 3.4

```
minishift openshift  config set --patch '{ "assetConfig" : { "metricsPublicURL" : "https://hawkular-metrics-openshift-infra.192.168.99.100.xip.io" } }'
minishift ssh 'echo "192.168.99.100 hawkular-metrics-openshift-infra.192.168.99.100.xip.io" | sudo tee -a /etc/hosts'
echo " 
  sudo yum install -y chrony
  sudo systemctl start chronyd
  sudo timedatectl set-ntp yes
  sudo timedatectl set-timezone America/New_York
  " | minishift ssh


oc project openshift-infra
oc adm policy add-role-to-user view system:serviceaccount:openshift-infra:hawkular -n openshift-infra
oc create -f - <<API
apiVersion: v1
kind: ServiceAccount
metadata:
  name: metrics-deployer
secrets:
- name: metrics-deployer
API
oc adm policy add-role-to-user edit system:serviceaccount:openshift-infra:metrics-deployer
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:openshift-infra:heapster
oc secrets new metrics-deployer nothing=/dev/null
oc process -f https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_hosted_templates/files/v1.4/enterprise/metrics-deployer.yaml -v HAWKULAR_METRICS_HOSTNAME=hawkular-metrics-openshift-infra.192.168.99.100.xip.io -v USE_PERSISTENT_STORAGE=false | oc create -f -
```

```
oc new-project ocp-ops-view
oc create sa kube-ops-view
oc adm policy add-scc-to-user anyuid -z kube-ops-view
oc adm policy add-cluster-role-to-user cluster-reader -z kube-ops-view
oc adm policy add-cluster-role-to-user system:hpa-controller -z kube-ops-view
oc apply -f https://raw.githubusercontent.com/raffaelespazzoli/kube-ops-view/ocp/deploy-openshift/kube-ops-view.yaml
oc expose svc kube-ops-view
oc get route | grep kube-ops-view | awk '{print $2}'
```
```
oc new-project ocp-ops-view
oc create sa kube-ops-view
oc adm policy add-scc-to-user anyuid -z kube-ops-view
oc adm policy add-cluster-role-to-user cluster-admin system:systemaccount:ocp-ops-view:kube-ops-view
oc apply -f https://raw.githubusercontent.com/raffaelespazzoli/kube-ops-view/ocp/deploy-openshift/kube-ops-view.yaml
oc expose svc kube-ops-view
oc get route | grep kube-ops-view | awk '{print $2}'
```
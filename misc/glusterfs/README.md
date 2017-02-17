# Glusterfs deployment in Openshift

You need to chose which nodes in your Openshift cluster will participate to your Gluster cluster.
These nodes need to:

1. have a specific label. For this example we will assume the label is: gluster=yes
2. have unused block devices. These block devices will be used by Gluster.

On your client machine install the following: heketi-client (`sudo dnf install -y heketi-client`).

When you are ready run the following commands to setup Gluster and Heketi in Openshift.

```
oc new-project glusterfs
oc patch namespace glusterfs --patch '{ "metadata":{"annotations": { "openshift.io/node-selector": "" }}}'
oc new-build https://github.com/raffaelespazzoli/openshift-enablement-exam --strategy=docker --context-dir=misc/glusterfs/initc --name=glusterfs
oc adm policy add-scc-to-user privileged -z default
oc policy add-role-to-user edit -z default
oc process -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/glusterfs/glusterfs.yaml -v GLUSTER_NODE_LABEL_VALUE=yes | oc create -f -
oc process -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/glusterfs/heketi.yaml -v HEKETI_KUBE_NAMESPACE=glusterfs HEKETI_KUBE_APIHOST='https://kubernetes.default.svc.cluster.local:443' HEKETI_KUBE_INSECURE=y HEKETI_KUBE_USER=admin HEKETI_KUBE_PASSWORD=admin | oc create -f -
```

In order to initialize Heketi with the Gluster cluster topology, ensure the topology file reflects your environment (you have to use nodes IPs) and then execute the following:
```
export  HEKETI_CLI_SERVER=http://`oc get route heketi | grep heketi | awk '{print $2}'`
heketi-cli topology load --json=gluster-topology.json
oc create -f heketi-storage.json
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/glusterfs/heketi-storage-pv.yaml
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/glusterfs/heketi-storage-pvc.yaml
oc volume dc/heketi --overwrite --add -m /var/lib/heketi --claim-name=heketi-storage-pvc

```  

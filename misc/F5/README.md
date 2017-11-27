create http and https virtual servers on F5. follow the documentation instructions

I called them openshift-http and openshift-https

export HTTP_VSERVER_NAME=openshift-http
export HTTPS_VSERVER_NAME=openshift-https

cat << EOF | oc create -f -
{
    "kind": "HostSubnet",
    "apiVersion": "v1",
    "metadata": {
        "name": "f5-1.etl.rht-labs.com",
        "annotations": {
        "pod.network.openshift.io/assign-subnet": "true",
        "pod.network.openshift.io/fixed-vnid-host": "0"  
        }
    },
    "host": "f5-1.etl.rht-labs.com",
    "hostIP": "10.9.55.11"  
} 
EOF

I discovered that `host` and `name` must be the same
oc adm policy add-scc-to-user privileged -z f5-router
oc adm policy add-cluster-role-to-user system:node-reader -z f5-router
oc adm policy add-cluster-role-to-user system:router -z f5-router  

no explained where `'/etc/openshift/master/openshift-router.kubeconfig'` is coming from.

oc adm router f5-router \
    --type=f5-router \
    --external-host=10.9.48.201 \
    --external-host-username=f5admin \
    --external-host-password=f5admin01 \
    --external-host-http-vserver=openshift-http \
    --external-host-https-vserver=openshift-https \
    --external-host-private-key=./f5-privatekey.pem \
    --service-account=f5-router \
    --host-network=false \
    --external-host-internal-ip=10.9.55.11 \
    --external-host-vxlan-gw=10.128.2.1/14 \
    --external-host-insecure=true
    
F5 must be able to validate the uploaded certificates. upload ca.crt to system > file management > ssl certificate list
created a new certificate called openshift.    

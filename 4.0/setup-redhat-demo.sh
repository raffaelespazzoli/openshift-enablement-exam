#start this cluster
#Red Hat OpenShift Container Platform 4 for Admins

export admin=kubeadmin
export pwd=$1
export api_url=$2

oc login -u $admin -p $pwd $api_url

oc create secret generic htpass-secret --from-file=htpasswd=./pwd/htpasswd -n openshift-config
oc apply -f ../misc4.0/htpasswd/oauth.yaml -n openshift-config
oc adm policy add-cluster-role-to-user cluster-admin raffa
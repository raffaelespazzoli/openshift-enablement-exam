
set -o nounset
set -o errexit

function create_openshift()
{
  export RELEASE_IMAGE=registry.svc.ci.openshift.org/ipv6/release:4.3.0-0.nightly-2020-02-17-205936-ipv6.1
  rm -f ./openshift-install
  ~/Downloads/openshift-client-linux-4.4.0-0.nightly-2020-02-17-103442/oc adm release extract -a ./config-azure/pullsecret.pretty.json --command=openshift-install $RELEASE_IMAGE  
  mkdir -p ./cluster-azure$CLUSTER_ID
  cp ./config-azure/install-config-raffa1.yaml ./cluster-azure$CLUSTER_ID/install-config.yaml
  #./openshift-install create cluster --dir ./cluster-azure$CLUSTER_ID --log-level debug
  OPENSHIFT_INSTALL_AZURE_EMULATE_SINGLESTACK_IPV6=true ./openshift-install create cluster --dir ./cluster-azure$CLUSTER_ID --log-level debug
  #OPENSHIFT_INSTALL_AZURE_EMULATE_SINGLESTACK_IPV6=true OPENSHIFT_INSTALL_AZURE_USE_IPV6=true OPENSHIFT_AZURE_USE_IPV6=true ./openshift-install create cluster --dir ./cluster-azure$CLUSTER_ID --log-level debug
  #OPENSHIFT_INSTALL_AWS_USE_IPV6=true OPENSHIFT_AWS_USE_IPV6=true ./openshift-install create cluster --dir ./cluster-azure$CLUSTER_ID --log-level debug
  export KUBECONFIG=/home/rspazzol/git/openshift-enablement-exam/4.0/cluster-azure$CLUSTER_ID/auth/kubeconfig
  # create route 
  oc create route reencrypt apiserver --service kubernetes --port https -n default
  # add simple user
  htpasswd -c -B -b ./cluster-azure$CLUSTER_ID/auth/htpasswd raffa raffa
  oc create secret generic htpass-secret --from-file=htpasswd=./cluster-azure$CLUSTER_ID/auth/htpasswd -n openshift-config
  oc apply -f ../misc4.0/htpasswd/oauth.yaml -n openshift-config
}

#download_installer
#configure_aws_credentials
CLUSTER_ID=1 create_openshift 
#CLUSTER_ID=2 create_openshift 
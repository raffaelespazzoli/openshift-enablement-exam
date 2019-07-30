
set -o nounset
set -o errexit

function create_openshift()
{
  mkdir -p ./cluster$CLUSTER_ID
  cp ./config/install-config-raffa$CLUSTER_ID.yaml ./cluster$CLUSTER_ID/install-config.yaml
  openshift-install create cluster --dir ./cluster$CLUSTER_ID --log-level debug
}

#download_installer
#configure_aws_credentials
CLUSTER_ID=1 create_openshift 
#CLUSTER_ID=2 create_openshift 
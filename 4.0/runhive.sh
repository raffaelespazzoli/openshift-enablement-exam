export CLUSTER_NAME=raffa1
export SSH_PUB_KEY=$(cat ~/.ssh/sshkey-gcp.pub)
export PULL_SECRET="$(cat ./config/pull-secret.json)"
export AWS_ACCESS_KEY_ID="$(cat ~/.aws/credentials | grep aws_access_key_id | awk '{ print$3 }')"
export AWS_SECRET_ACCESS_KEY="$(cat ~/.aws/credentials | grep aws_secret_access_key | awk '{ print$3 }')"
export BASE_DOMAIN=sandbox205.opentlc.com
export REGION=us-west-1


oc process -f ./hive-template/cluster-deployment.yaml \
   CLUSTER_NAME="${CLUSTER_NAME}" \
   SSH_KEY="${SSH_PUB_KEY}" \
   PULL_SECRET="${PULL_SECRET}" \
   AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
   AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
   BASE_DOMAIN=${BASE_DOMAIN} \
   REGION=${REGION} \
   | oc apply -f -
   
oc process -f ./hive-template/cluster-deployment.yaml \
   CLUSTER_NAME="${CLUSTER_NAME}" \
   SSH_KEY="${SSH_PUB_KEY}" \
   PULL_SECRET="${PULL_SECRET}" \
   AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" \
   AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" \
   BASE_DOMAIN=${BASE_DOMAIN} \
   REGION=${REGION} \
   | oc delete -f -   
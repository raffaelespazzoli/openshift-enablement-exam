#https://access.redhat.com/solutions/3826921

AWS_REGION=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.aws.region}')
CLUSTER_NAME=cluster1
INFRA_ID=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
echo "{\"clusterName\":\"${CLUSTER_NAME}\",\"clusterID\":\"\",\"infraID\":\"${INFRA_ID}\",\"aws\":{\"region\":\"${AWS_REGION}\",\"identifier\":[{\"kubernetes.io/cluster/${INFRA_ID}\":\"owned\"}]}}" > metadata.json
openshift-install  destroy cluster --log-level=debug --dir ./cluster1
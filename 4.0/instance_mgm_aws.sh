#this function receves in input a list of cluster ids as found in the tag: kubernetes.io/cluster/<id>: owned

set -o nounset
set -o errexit

function stop() {
  for region in us-east-1 us-east-2 us-west-1 us-west-2; do
    for clusterid in $@; do
      instances=$(aws --region ${region} ec2 describe-instances --filters Name=tag:kubernetes.io/cluster/${clusterid},Values=owned Name=instance-state-name,Values=running | jq -r .Reservations[].Instances[].InstanceId | tr "\n" " ")
      if [ ! -z "${instances}" ]; then
        aws --region ${region} ec2 stop-instances --instance-ids ${instances}
      fi
    done
  done      
}

function start() {
  for region in us-east-1 us-east-2 us-west-1 us-west-2; do
    for clusterid in $@; do
      instances=$(aws --region ${region} ec2 describe-instances --filters Name=tag:kubernetes.io/cluster/${clusterid},Values=owned Name=instance-state-name,Values=stopped | jq -r .Reservations[].Instances[].InstanceId | tr "\n" " ")
      echo for region $region found instances $instances
      if [ ! -z "${instances}" ]; then
        aws --region ${region} ec2 start-instances --instance-ids ${instances}
      fi
    done
  done      
}

if [ "$1" == "start" ]; then
  shift
  start $@
fi

if [ "$1" == "stop" ]; then
  shift
  stop $@
fi 
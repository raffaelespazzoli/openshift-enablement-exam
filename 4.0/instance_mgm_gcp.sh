#this function receves in input a list of cluster ids as found in the tag: kubernetes.io/cluster/<id>: owned

set -o nounset
set -o errexit

export regions=("us-east4" "us-central1" "us-west1")
export zone_suffixes=("-a" "-b" "-c")

function stop() {
  for clusterid in $@; do
    for region in "${regions[@]}"; do
      for zone_suffix in "${zone_suffixes[@]}"; do
        instances=$(gcloud compute instances list --zones=${region}${zone_suffix} --filter="labels.kubernetes-io-cluster-${clusterid}:owned AND status=RUNNING" --format json | jq -r .[].name | tr "\n" " ")
        echo found instances $instances
        if [ ! -z "${instances}" ]; then
          gcloud compute instances stop ${instances} --async --zone=${region}${zone_suffix}
        fi
      done
    done
  done     
}

function start() {
  for clusterid in $@; do
    for region in "${regions[@]}"; do
      for zone_suffix in "${zone_suffixes[@]}"; do
        instances=$(gcloud compute instances list --zones=${region}${zone_suffix} --filter="labels.kubernetes-io-cluster-${clusterid}:owned AND status=TERMINATED" --format json | jq -r .[].name | tr "\n" " ")
        echo found instances $instances
        if [ ! -z "${instances}" ]; then
          gcloud compute instances start ${instances} --async --zone=${region}${zone_suffix}
        fi
      done
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
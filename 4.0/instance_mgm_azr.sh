#this function receves in input a list of cluster ids as found in the tag: kubernetes.io/cluster/<id>: owned

set -o nounset
set -o errexit

function stop() {
  for clusterid in $@; do
    instances=$(az vm list -d --resource-group ${clusterid}-rg | jq -r '.[] | select(.powerState == "VM stopped" or .powerState == "VM running") | .id' | tr "\n" " ")
    echo found instances $instances
    if [ ! -z "${instances}" ]; then
      az vm deallocate --ids ${instances} --no-wait
    fi
  done     
}

function start() {
  for clusterid in $@; do
    instances=$(az vm list -d --resource-group ${clusterid}-rg | jq -r '.[] | select(.powerState == "VM stopped" or .powerState == "VM deallocated") | .id' | tr "\n" " ")
    echo found instances $instances
    if [ ! -z "${instances}" ]; then
      az vm start --ids ${instances} --no-wait
    fi
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
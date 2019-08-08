# Rook

## deploy ceph VMs

```
export cluster_uuid=$(oc get clusterversions.config.openshift.io version -o jsonpath='{.spec.clusterID}{"\n"}')
export infra_id=$(oc get infrastructures.config.openshift.io cluster -o jsonpath='{.status.infrastructureName}{"\n"}')
export region=$(oc get machines -n openshift-machine-api | grep -m 1 master | awk '{print $5}')
export azs=$(oc get machines -n openshift-machine-api | grep master | awk '{print $6}')
for az in $azs; do
  az=$az envsubst < rook-machines.yaml | oc apply -f - -n openshift-machine-api
done
```

## attach ceph volumes

```
for machine in $(oc get machine -n openshift-machine-api | grep rook | awk '{print $1}'); do
  instance_id=$(oc get machine $machine -n openshift-machine-api -o jsonpath='{.status.providerStatus.instanceId}')
  echo working on machine $machine instance $instance_id
  availability_zone=$(oc get machine $machine -n openshift-machine-api -o jsonpath='{.spec.providerSpec.value.placement.availabilityZone}')
  region=$(oc get machine $machine -n openshift-machine-api -o jsonpath='{.spec.providerSpec.value.placement.region}')
  echo creating volume in availability zone $availability_zone and region $region
  volume_id=$(aws ec2 create-volume --region $region --availability-zone $availability_zone --volume-type=gp2 --size 200 --output json | jq -r .VolumeId)
  sleep 5
  echo attaching volume $volume_id to instance $instance_id 
  aws ec2 attach-volume --region $region --instance-id $instance_id --volume-id $volume_id --device /dev/sdr
done
```

## Deploy the operator

```
oc new-project rook-ceph
oc apply -f rook-openshift/common.yaml -n rook-ceph
oc apply -f rook-openshift/operator-openshift.yaml -n rook-ceph
oc apply -f ceph-cluster.yaml -n rook-ceph
# after a few seconds
sleep 20
oc set image statefulset/csi-rbdplugin-provisioner csi-snapshotter=quay.io/k8scsi/csi-snapshotter:v1.2.0 -n rook-ceph
oc scale statefulset/csi-rbdplugin-provisioner --replicas 0
oc scale statefulset/csi-rbdplugin-provisioner --replicas 1
oc apply -f rook-openshift/filesystem.yaml -n rook-ceph
oc apply -f rook-openshift/toolbox.yaml -n rook-ceph
oc apply -f rook-openshift/storageclasses/cephfs-storageclass.yaml -n rook-ceph
oc apply -f rook-openshift/storageclasses/rbd-storageclass.yaml -n rook-ceph
```

## Debug rook

```
oc -n rook-ceph exec -it $(kubectl -n rook-ceph get pod -l "app=rook-ceph-tools" -o jsonpath='{.items[0].metadata.name}') bash
```

then execute ceph commands
```
ceph status
```


```

# Installing KubeSAN

## Configure node-level prerequisites

create a pull secret called pull-secret in `openshift-machine-config-operator` namespace

```sh
oc patch featuregate cluster --type='merge' -p '{"spec":{"featureSet":"TechPreviewNoUpgrade"}}'
export docker_secret=$(oc get secret -n openshift-machine-config-operator --field-selector=type="kubernetes.io/dockercfg" -o custom-columns=NAME:.metadata.name | grep machine-os-builder)
envsubst < ./machine-os-layering.yaml | oc apply -f - 
oc apply -f ./machine-config.yaml
  
```

```
oc apply -f ./machine-config.yaml
```

## Configure the large SAN volume on each node


## Configure LVM around the large SAN volume

## Deploy and configure KubeSAN

```sh
oc apply -k https://gitlab.com/kubesan/kubesan/deploy/openshift?ref=v0.4.0


oc apply -k "https://github.com/kubernetes-csi/external-snapshotter/client/config/crd?ref=v7.0.1"
oc apply -k "https://github.com/kubernetes-csi/external-snapshotter/deploy/kubernetes/snapshot-controller?ref=v7.0.1"
oc apply -f ./volume-snapshot-class.yaml
oc apply -f ./storage-classes.yaml
for sc in san-vg-5gb san-vg-50gb san-vg-100gb;do
  oc patch storageprofile ${sc} --type=merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteOnce", "ReadOnlyMany", "ReadWriteMany"], "volumeMode": "Block"}, {"accessModes": ["ReadWriteOnce"], "volumeMode": "Filesystem"}], "cloneStrategy": "csi-clone"}}';
done  
```

dmidcode

export id=$(hostname -I | awk '{ print $1 }' | cut -d . -f 4)
envsubst < /etc/lvm/lvmlocal.conf.tmpl > /etc/lvm/lvmlocal.conf


systemctl status sanlock.service lvmlockd.service kubesan_assign_lvm_id.service connect-luns.service initialize_vgs.service



kubectl patch storageprofile san-vg-5gb --type=merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteOnce", "ReadOnlyMany", "ReadWriteMany"], "volumeMode": "Block"}, {"accessModes": ["ReadWriteOnce"], "volumeMode": "Filesystem"}], "cloneStrategy": "csi-clone"}}'
kubectl patch storageprofile san-vg-50gb --type=merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteOnce", "ReadOnlyMany", "ReadWriteMany"], "volumeMode": "Block"}, {"accessModes": ["ReadWriteOnce"], "volumeMode": "Filesystem"}], "cloneStrategy": "csi-clone"}}'
kubectl patch storageprofile san-vg-100gb --type=merge -p '{"spec": {"claimPropertySets": [{"accessModes": ["ReadWriteOnce", "ReadOnlyMany", "ReadWriteMany"], "volumeMode": "Block"}, {"accessModes": ["ReadWriteOnce"], "volumeMode": "Filesystem"}], "cloneStrategy": "csi-clone"}}'

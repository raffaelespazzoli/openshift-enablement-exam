# configuring local storage

create a directory that will be used for local storage, in theory you should mount a disk here
```
ansible nodes -b -i hosts -m shell -a "mkdir -p -m 777 /mnt/local-storage"
```
create a config map that describe the storage layout
```
oc adm new-project local-storage --node-selector=""
oc apply -f ./local-storage-cm.yaml
```
deploy the local storage controller:
```
oc create serviceaccount local-storage-admin
oc adm policy add-scc-to-user hostmount-anyuid -z local-storage-admin
oc create -f https://raw.githubusercontent.com/jsafrane/origin/local-storage/examples/storage-examples/local-examples/local-storage-provisioner-template.yaml
oc process -p CONFIGMAP=local-volume-config -p SERVICE_ACCOUNT=local-storage-admin -p NAMESPACE=local-storage local-storage-provisioner | oc apply -f -
```
```
oc new-project rook-system
oc adm policy add-cluster-role-to-user cluster-admin -z rook-operator
oc create -f https://raw.githubusercontent.com/rook/rook/master/cluster/examples/kubernetes/rook-operator.yaml

oc new-project rook
cat << EOF | kubectl create -f -
apiVersion: rook.io/v1alpha1
kind: Cluster
metadata:
  name: rook
spec:
  versionTag: master
  dataDirHostPath: "/etc/rook"
  # cluster level storage configuration and selection
  storage:                
    useAllNodes: false
    useAllDevices: false
    deviceFilter: "/dev/vdc"
    metadataDevice:
    location:
    storeConfig:
      storeType: bluestore
      databaseSizeMB: 1024 # this value can be removed for environments with normal sized disks (100 GB or larger)
      journalSizeMB: 1024  # this value can be removed for environments with normal sized disks (20 GB or larger)
    nodes:
    - name: "app-node-0.env1.casl.raffa.com"
    - name: "app-node-1.env1.casl.raffa.com"
    - name: "app-node-2.env1.casl.raffa.com"
EOF    

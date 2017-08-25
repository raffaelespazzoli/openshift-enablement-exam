
cd /home/rspazzol/git/casl-ansible/
ansible-galaxy install -r casl-requirements.yml -p roles
cd docker/control-host-openstack
docker-compose up -d
docker exec -it controlhostopenstack_control-host_1 bash
openstack stack delete -y env1.casl.raffa.com
ansible-playbook -vv -i /root/code/casl-ansible/inventory/raffa.casl.example.com/inventory /root/code/casl-ansible/playbooks/openshift/end-to-end.yml -e openstack_ssh_public_key=rspazzol-etl --private-key=.ssh/rspazzol-etl.pem








cat << EOF | oc create -f -
  apiVersion: v1
  kind: PersistentVolume
  metadata:
    name: nfs-dvp-pv
  spec:
    capacity:
      storage: 100G
    accessModes:
      - ReadWriteOnce
    persistentVolumeReclaimPolicy: Retain
    hostPath:
      path: /exports/exports
EOF

cat << EOF | oc create -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-dpv-pvc
spec:
  accessModes:232418
  - ReadWriteOnce
  resources:
    requests:
      storage: 100G
  volumeName: nfs-dvp-pv
EOF


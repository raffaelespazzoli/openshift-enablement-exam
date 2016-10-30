#!/bin/bash
set -e

#crate necessary dirs in nfs server

ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'for i in {1..30} do echo "/exports/pv$i *(rw,root_squash)" | sudo tee -a /etc/exports.d/openshift-ansible.exports > /dev/null done'
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'for i in {1..30} do sudo mkdir "/exports/pv$i && sudo chown nfsnobody:nfsnobody "/exports/pv$i && sudo chmod 777 "/exports/pv$i done'

#restart nfs
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo systemctl restart nfs

# create pvs 
for i in {1..30}; do
	oc process -f pv_template.yaml -v NFS_EXPORT="pv$i",PV_NAME="pv$i"
done
#!/bin/bash
set -e

#crate necessary dirs in nfs server
for i in {1..30}; do
	ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'echo "/exports/pv$i *(rw,root_squash)" | sudo tee -a /etc/exports.d/openshift-ansible.exports > /dev/null'
	ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo mkdir "/exports/pv$i"
	ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo chown nfsnobody:nfsnobody "/exports/pv$i"
	ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo chmod 777 "/exports/pv$i"
done

#restart nfs
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo systemctl restart nfs

# create pvs 
for i in {1..30}; do
	oc process -f pv_template.yaml -v NFS_EXPORT="pv$i",PV_NAME="pv$i"
done
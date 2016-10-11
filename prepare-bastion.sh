#!/bin/bash

set -e
ansible nfs -b -i hosts -m shell -a 'yum install -y subscription-manager && subscription-manager clean && subscription-manager register --username=$RHN_USERNAME --password=$RHN_PASSWORD && subscription-manager attach --pool=8a85f9843e3d687a013e3ddd471a083e && subscription-manager refresh && subscription-manager repos --disable="*" && subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-ose-3.3-rpms" && yum update -y && yum install -y git ansible atomic-openshift-utils && echo StrictHostKeyChecking no >> /etc/ssh/ssh_config'
# generate and add keys
ssh `gcloud compute instance describe ose-bastion region us-central1 | grep address: | awk '{print $2}'` ssh-keygen -t rsa -f .ssh/id_rsa -N ''
ssh `gcloud compute instance describe ose-bastion region us-central1 | grep address: | awk '{print $2}'` cat /home/rspazzol/.ssh/id_rsa.pub | gcloud compute project-info add-metadata --metadata-from-file sshKeys=-
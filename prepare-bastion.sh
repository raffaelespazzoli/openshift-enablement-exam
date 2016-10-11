#!/bin/bash

set -e
#install subcription manager and clean
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'sudo yum install -y subscription-manager && sudo subscription-manager clean'
#subscribe
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo subscription-manager register --username=$RHN_USERNAME --password=$RHN_PASSWORD
# configure subscriptions
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'sudo subscription-manager attach --pool=8a85f9843e3d687a013e3ddd471a083e && sudo subscription-manager refresh && sudo subscription-manager repos --disable="*" && sudo subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-ose-3.3-rpms"'
#update install packages
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'sudo yum update -y && sudo yum install -y git ansible atomic-openshift-utils'
# generate and add keys
ssh `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` ssh-keygen -t rsa -f .ssh/id_rsa -N ''
# set the key in gcloud metadata
ssh `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` cat /home/rspazzol/.ssh/id_rsa.pub | gcloud compute project-info add-metadata --metadata-from-file sshKeys=-

#!/bin/bash

set -e
# set the ssh key
cp $SSH_PUB_KEY ./my_id.pub 
export BASTION_USERNAME=`whoami`
platform='unknown'
unamestr=`uname`
if [[ "$unamestr" == 'Linux' ]]; then
   echo "Creating a Linux Key"
   sed -i "s/^/$BASTION_USERNAME:/" ./my_id.pub
elif [[ "$unamestr" == 'Darwin' ]]; then
   echo "Creating a Darwin Key"
   sed -i '' "s/^/$BASTION_USERNAME:/" ./my_id.pub
fi


gcloud compute project-info add-metadata --metadata-from-file sshKeys=./my_id.pub
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'echo AcceptEnv RHN_USERNAME RHN_PASSWORD DNS_DOMAIN RHN_SUB_POOL BASTION_USERNAME | sudo tee -a /etc/ssh/sshd_config > /dev/null'
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo systemctl restart sshd
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` -o SendEnv=RHN_USERNAME -o SendEnv=RHN_PASSWORD -o SendEnv=DNS_DOMAIN -o SendEnv=RHN_SUB_POOL -o SendEnv=BASTION_USERNAME 'echo "$RHN_USERNAME $RHN_PASSWORD $DNS_DOMAIN $RHN_SUB_POOL $BASTION_USERNAME"'

#install subcription manager and clean
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'sudo yum install -y subscription-manager && sudo subscription-manager clean'
#subscribe
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` -o SendEnv=RHN_USERNAME -o SendEnv=RHN_PASSWORD 'sudo subscription-manager register --username=$RHN_USERNAME --password=$RHN_PASSWORD'
# configure subscriptions
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` -o SendEnv=RHN_SUB_POOL 'sudo subscription-manager attach --pool=$RHN_SUB_POOL && sudo subscription-manager refresh && sudo subscription-manager repos --disable="*" && sudo subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-ose-3.3-rpms"'
#update install packages
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'sudo yum update -y && sudo yum install -y git ansible atomic-openshift-utils'
# generate and add keys
ssh `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'ssh-keygen -t rsa -f .ssh/id_rsa -N ""'
# set the key in gcloud metadata
ssh `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` -o SendEnv=BASTION_USERNAME 'cat /home/$BASTION_USERNAME/.ssh/id_rsa.pub' >  ./id_rsa.pub


if [[ "$unamestr" == 'Linux' ]]; then
   echo "Creating a Linux Key"
   sed -i "s/^/$BASTION_USERNAME:/" ./id_rsa.pub
elif [[ "$unamestr" == 'Darwin' ]]; then
   echo "Creating a Darwin Key"
   sed -i '' "s/^/$BASTION_USERNAME:/" ./id_rsa.pub
fi

cat id_rsa.pub >> my_id.pub
gcloud compute project-info add-metadata --metadata-from-file sshKeys=./my_id.pub

# prepare bastion to receive variables
#ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'echo AcceptEnv RHN_USERNAME RHN_PASSWORD DNS_DOMAIN | sudo tee -a /etc/ssh/sshd_config > /dev/null'
#ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo systemctl restart sshd

# disable host check on ssh connections
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'echo StrictHostKeyChecking no | sudo tee -a /etc/ssh/ssh_config > /dev/null'
# download git
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` git clone https://github.com/raffaelespazzoli/openshift-enablement-exam

unset BASTION_USERNAME
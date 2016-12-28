#!/bin/bash

set -e
# set the ssh key
cp $SSH_PUB_KEY ./my_id.pub 
a=`whoami` 
sed -i "s/^/$a:/" ./my_id.pub
export BASTION_USERNAME=$a

gcloud compute project-info add-metadata --metadata-from-file sshKeys=./my_id.pub

# prepare bastion to receive variables
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'echo AcceptEnv RHN_USERNAME RHN_PASSWORD DNS_DOMAIN BASTION_USERNAME RHN_SUB_POOL | sudo tee -a /etc/ssh/sshd_config > /dev/null'
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo systemctl restart sshd
# disable host check on ssh connections
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'echo StrictHostKeyChecking no | sudo tee -a /etc/ssh/ssh_config > /dev/null'	


#install subcription manager and clean
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'sudo yum install -y subscription-manager && sudo subscription-manager clean'
#subscribe
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo subscription-manager register --username=$RHN_USERNAME --password=$RHN_PASSWORD
# configure subscriptions
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` -o SendEnv=RHN_USERNAME -o SendEnv=RHN_PASSWORD -o SendEnv=DNS_DOMAIN -o SendEnv=RHN_SUB_POOL -o SendEnv=BASTION_USERNAME 'sudo subscription-manager attach --pool=$RHN_SUB_POOL && sudo subscription-manager refresh && sudo subscription-manager repos --disable="*" && sudo subscription-manager repos --enable="rhel-7-server-rpms" --enable="rhel-7-server-optional-rpms" --enable="rhel-7-server-extras-rpms" --enable="rhel-7-server-ose-3.3-rpms"'
#update install packages
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'sudo yum update -y && sudo yum install -y git ansible atomic-openshift-utils screen bind-utils'
# generate and add keys
ssh `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'ssh-keygen -t rsa -f .ssh/id_rsa -N ""'
# set the key in gcloud metadata
ssh `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'cat /home/rspazzol/.ssh/id_rsa.pub' >  ./id_rsa.pub
sed -i "s/^/$a:/" ./id_rsa.pub
cat id_rsa.pub >> my_id.pub
gcloud compute project-info add-metadata --metadata-from-file sshKeys=./my_id.pub


# download git
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` git clone https://github.com/raffaelespazzoli/openshift-enablement-exam

# prepare hostfile
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` -o SendEnv=RHN_USERNAME -o SendEnv=RHN_PASSWORD -o SendEnv=DNS_DOMAIN -o SendEnv=RHN_SUB_POOL -o SendEnv=BASTION_USERNAME 'sed -i "s/master.10.128.0.10.xip.io/mi.$DNS_DOMAIN/g" /home/$BASTION_USERNAME/openshift-enablement-exam/hosts'
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` -o SendEnv=RHN_USERNAME -o SendEnv=RHN_PASSWORD -o SendEnv=DNS_DOMAIN -o SendEnv=RHN_SUB_POOL -o SendEnv=BASTION_USERNAME 'sed -i "s/master.104.197.199.131.xip.io/master.$DNS_DOMAIN/g" /home/$BASTION_USERNAME/openshift-enablement-exam/hosts'
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` -o SendEnv=RHN_USERNAME -o SendEnv=RHN_PASSWORD -o SendEnv=DNS_DOMAIN -o SendEnv=RHN_SUB_POOL -o SendEnv=BASTION_USERNAME 'sed -i "s/apps.104.198.35.122.xip.io/apps.$DNS_DOMAIN/g" /home/$BASTION_USERNAME/openshift-enablement-exam/hosts'
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` -o SendEnv=RHN_USERNAME -o SendEnv=RHN_PASSWORD -o SendEnv=DNS_DOMAIN -o SendEnv=RHN_SUB_POOL -o SendEnv=BASTION_USERNAME 'sed -i "s/BASTION_USERNAME/$BASTION_USERNAME/g" /home/$BASTION_USERNAME/openshift-enablement-exam/hosts'

#delete temporary key files
rm id_rsa.pub my_id.pub

#reboot
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` 'sudo reboot'
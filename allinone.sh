#!/bin/bash

./povision-gcp.sh
./prepare-bastion.sh
ssh -o SendEnv=RHN_USERNAME -o SendEnv=RHN_PASSWORD -o SendEnv=DNS_DOMAIN -o SendEnv=RHN_SUB_POOL `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` "cd openshift-enablement-exam && ./prepare-cluster.sh"
echo "sleeping 20 second waiting for the reboot"
sleep 20
ssh -o SendEnv=RHN_USERNAME -o SendEnv=RHN_PASSWORD -o SendEnv=DNS_DOMAIN -o SendEnv=RHN_SUB_POOL `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` "cd openshift-enablement-exam && ansible-playbook -v -i hosts /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml"
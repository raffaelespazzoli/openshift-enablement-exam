#!/bin/bash
set -e

# Prepare Cluster 
ansible nodes -b -i hosts -m shell -a "yum install -y subscription-manager && subscription-manager clean && subscription-manager register --username=$RHN_USERNAME --password=$RHN_PASSWORD && subscription-manager attach --pool=8a85f9843e3d687a013e3ddd471a083e && subscription-manager refresh && subscription-manager repos --disable='*' && subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-optional-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-ose-3.3-rpms && yum update -y && yum install -y wget git net-tools bind-utils iptables-services bridge-utils bash-completion"
ansible 'nodes:!masters' -i hosts -b -m copy -a "src=docker-storage-setup dest=/etc/sysconfig/docker-storage-setup"
ansible 'nodes:!masters' -i hosts -b -m shell -a "yum install -y docker && docker-storage-setup"
ansible nodes -b -i hosts -m shell -a "reboot"
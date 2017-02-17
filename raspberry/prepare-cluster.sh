#!/bin/bash
set -e

# Prepare Cluster 
ansible nodes -b -i hosts -m shell -a "dnf update -y"
ansible nodes -b -i hosts -m shell -a "dnf install -y dnf install -y python2 python2-dnf libselinux-python libsemanage-python python2-firewall pyOpenSSL python-cryptography"
ansible nodes -b -i hosts -m shell -a "dnf install -y tar wget git net-tools bind-utils iptables-services bridge-utils bash-completion"
ansible 'nodes:!masters' -i hosts -b -m shell -a "dnf install -y docker"
ansible nodes -b -i hosts -m package -a "name=NetworkManager state=present use=dnf"
ansible nodes -b -i hosts -m service -a "name=NetworkManager enabled=true state=started"
ansible nodes -b -i hosts -m shell -a "reboot"


Dec 16 19:38:35 master origin-node[26673]: Invalid NodeConfig /etc/origin/node/node-config.yaml
Dec 16 19:38:35 master origin-node[26673]:   masterKubeConfig: Invalid value: "/etc/origin/node/system:node:192.168.0.2.kubeconfig": could not read file
	
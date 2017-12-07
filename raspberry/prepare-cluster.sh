#!/bin/bash
set -e

# Prepare Cluster 
ansible nodes -b -i hosts -m shell -a "dnf update -y"
ansible nodes -b -i hosts -m shell -a "dnf install -y python3 python3-dnf python3-PyYAML libselinux-python libsemanage-python python3-firewall pyOpenSSL python-cryptography tar wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker"
ansible nodes -b -i hosts -m package -a "name=NetworkManager state=present use=dnf"
ansible nodes -b -i hosts -m service -a "name=NetworkManager enabled=true state=started"
ansible nodes -b -i hosts -m shell -a "reboot"


Dec 16 19:38:35 master origin-node[26673]: Invalid NodeConfig /etc/origin/node/node-config.yaml
Dec 16 19:38:35 master origin-node[26673]:   masterKubeConfig: Invalid value: "/etc/origin/node/system:node:192.168.0.2.kubeconfig": could not read file
	
	
	
alternatives --install /usr/bin/python python /usr/bin/python3.6 2
alternatives --install /usr/bin/python python /usr/bin/python2.7 1

vi /usr/lib/systemd/system/etcd.service
add Environment=ETCD_UNSUPPORTED_ARCH=arm64

##Turbo
#arm_freq=1000
#core_freq=500
#sdram_freq=500
#over_voltage=6


192.168.0.50 master master.raspi3.oc
192.168.0.51 infranode infranode.raspi3.oc
192.168.0.52 node1 node1.raspi3.oc
192.168.0.53 node2 node2.raspi3.oc

vi /usr/lib/systemd/system/tuned.service
ExecStart=/usr/bin/python2.7 /usr/sbin/tuned -l -P

for i in "pod" "deployer" "recycler" "keepalived-ipfailover" "haproxy-router" "docker-registry" "custom-docker-builder" "docker-builder" "sti-builder"; do docker pull docker.io/raffaelespazzoli/origin-$i-arm64:latest; done

origin-excluder unexclude
origin-docker-excluder unexclude

systemctl stop initial-setup.service
systemctl disable initial-setup.service


ln -s /opt/cni/bin /usr/libexec/cni

oc new-project myproject
oc new-app arm64v8/nginx --name nignx
# Installation

due to an issue nodes must be routable between each other at the moment. this is up to you to setup.If in CASL follow the below:

## setup casl routing
```
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "reboot"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "reboot"
sleep 60
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "ip route add 192.168.99.0/24 via 192.168.98.254"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "ip route add 192.168.98.0/24 via 192.168.99.254"

#ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "iptables -A INPUT -p udp -m udp --dport 5555 -j ACCEPT"
#ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "iptables -A INPUT -p udp -m udp --dport 5555 -j ACCEPT"

#ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "iptables -A INPUT -p udp -m udp --dport 30000:40000 -j ACCEPT"
#ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "iptables -A INPUT -p udp -m udp --dport 30000:40000 -j ACCEPT"
```
## install wireguard
```
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "yum install -y epel-release-latest-7.noarch.rpm"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "yum install -y wireguard-dkms wireguard-tools"

ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "yum install -y epel-release-latest-7.noarch.rpm"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "yum install -y wireguard-dkms wireguard-tools"
```

## run the installation playbook

see an example of the inventory here ./ansible/inventory and customize for your clusters
run the playbook:
```
ansible-playbook -i ./ansible/inventory ./ansible/playbooks/deploy-wireguard/config.yaml
```


## old notes
```
CLUSTER1_LB_IP=192.168.99.14
CLUSTER2_LB_IP=192.168.98.13
oc login <cluster1>
CLUSTER1=$(oc config current-context)
oc login <cluster2>
CLUSTER2=$(oc config current-context)

CLUSTER1_CIDR=$(oc --context $CLUSTER1 get clusternetwork default -o custom-columns=CIDR:.clusterNetworks[0].CIDR --no-headers)
CLUSTER2_CIDR=$(oc --context $CLUSTER2 get clusternetwork default -o custom-columns=CIDR:.clusterNetworks[0].CIDR --no-headers)

oc --context $CLUSTER1 adm new-project istio-mesh-extension --node-selector=""
oc --context $CLUSTER2 adm new-project istio-mesh-extension --node-selector=""

wg genkey | tee privatekey1 | wg pubkey > publickey1
wg genkey | tee privatekey2 | wg pubkey > publickey2

CLUSTER1_PRK=$(<privatekey1)
CLUSTER1_PUK=$(<publickey1)
CLUSTER2_PRK=$(<privatekey2)
CLUSTER2_PUK=$(<publickey2)

helm template -n istio-mesh-extension --set tunnelPort=32011,serviceType=NodePort,tunnelPrivateKey=$CLUSTER1_PRK,tunnelPeerPublicKey=$CLUSTER2_PUK,image.pullPolicy=Always,tunnelCIDR=$CLUSTER2_CIDR,tunnelRemotePeer=$CLUSTER2_LB_IP,tunnelMode=wireguard istio-mesh-extension | oc --context $CLUSTER1 apply -f -
helm template -n istio-mesh-extension --set tunnelPort=32011,serviceType=NodePort,tunnelPrivateKey=$CLUSTER2_PRK,tunnelPeerPublicKey=$CLUSTER1_PUK,image.pullPolicy=Always,tunnelCIDR=$CLUSTER1_CIDR,tunnelRemotePeer=$CLUSTER1_LB_IP,tunnelMode=wireguard istio-mesh-extension | oc --context $CLUSTER2 apply -f -
```




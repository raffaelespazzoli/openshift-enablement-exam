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


helm template -n istio-mesh-extension --set tunnelCIDR=$CLUSTER2_CIDR,tunnelRemotePeer=$CLUSTER2_LB_IP,tunnelMode=wireguard istio-mesh-extension | oc --context $CLUSTER1 apply -f -
helm template -n istio-mesh-extension --set tunnelCIDR=$CLUSTER1_CIDR,tunnelRemotePeer=$CLUSTER1_LB_IP,tunnelMode=wireguard istio-mesh-extension | oc --context $CLUSTER2 apply -f -
```


setup casl routing
```
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "ip route add 192.168.99.0/24 via 192.168.98.254"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "ip route add 192.168.98.0/24 via 192.168.99.254"

ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "iptables -A INPUT -p udp -m udp --dport 5555 -j ACCEPT"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "iptables -A INPUT -p udp -m udp --dport 5555 -j ACCEPT"
```
install wg
```
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "yum install -y epel-release-latest-7.noarch.rpm"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory-mini --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "yum install -y wireguard-dkms wireguard-tools"

ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "curl -Lo /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "wget https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "yum install -y epel-release-latest-7.noarch.rpm"
ansible nodes -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol -m shell -a "yum install -y wireguard-dkms wireguard-tools"


#!/usr/bin/env bash

#### this script uses the following environment variables
# TUNNEL_PORT : the port used to establish the tunnel
# TUNNEL_DEV_NAME : the device used to establush the tunnel
# TUNNEL_REMOTE_PEER : the peer IP or VIP to which establish the tunnel 
# TUNNEL_LOCAL_PEER : the local IP to be used for the tunnel
# TUNNEL_CIDR : the CIDR that should be routed thoru this tunnel in x.x.x.x/x format
# TUNNEL_PRIVATE_KEY: the private key
# TUNNEL_PEER_PUBLIC_KEY: the peer's public key
# TUNNEL_MODE: implementnation of the tunnel (fou, socat, socatcs, wireguard)
# WIREGUARD_CONFIG: location of the wireguard config file
# CLUSTER_CIDR: the cidr of the current cluster
# TUNNEL_CIDRs: comma separated CIDRs of the remote clusters
# PEER_CONFIG: location of the PEER_CONFIG file
# NODEIP_CIDR: location of the node_ip-cidr config file  


set -o nounset
set -o errexit

function setupFouTunnel {
  echo running setupFouTunnel
  ip fou add port $TUNNEL_PORT ipproto 4
  ip link add name $TUNNEL_DEV_NAME type ipip remote $TUNNEL_REMOTE_PEER local $TUNNEL_LOCAL_PEER ttl 225 encap fou encap-sport \
    auto encap-dport $TUNNEL_PORT
  ip addr add $TUNNEL_CIDR dev $TUNNEL_DEV_NAME
  }

# wg created in node's network namespace and moved to pod's network namespace

function setupWg4 {
  echo running setupwg4
  sysctl -w net.ipv4.ip_forward=1
#  sysctl -w net.ipv4.conf.all.proxy_arp=1
  nsenter -t 1 -n ip link add dev $TUNNEL_DEV_NAME type wireguard
  nsenter -t 1 -n ip link set $TUNNEL_DEV_NAME netns $$
  wg setconf $TUNNEL_DEV_NAME $WIREGUARD_CONFIG
  ip link set up dev $TUNNEL_DEV_NAME
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    ip route add $cidr dev $TUNNEL_DEV_NAME proto static scope global
  done    
}


# wg completely in the pod's network namespace

function setupWg1 {
  echo running setupwg1
  sysctl -w net.ipv4.ip_forward=1
  ip link add dev $TUNNEL_DEV_NAME type wireguard
  #ip link set $TUNNEL_DEV_NAME netns $$
  wg setconf $TUNNEL_DEV_NAME $WIREGUARD_CONFIG
  ip link set up dev $TUNNEL_DEV_NAME
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    ip route add $cidr dev $TUNNEL_DEV_NAME
  done    
}

function setup {
  echo running setup
  
  if [ $TUNNEL_MODE = "fou" ] 
  then
    setupFouTunnel
    wireOVSPodInOut   
  elif [ $TUNNEL_MODE = "wireguard1" ] 
  then
#    setupIPTables
    setupWg1
    wireOVSPodInOut
  elif [ $TUNNEL_MODE = "wireguard4" ] 
  then
    setupWg4
    wireOVSPodInOut             
  fi   
  }

function cleanup {
  echo running cleanup

  if [ $TUNNEL_MODE = "fou" ] 
  then
    unwireOVSPodInOut
  elif [ $TUNNEL_MODE = "wireguard1" ] 
  then
    unwireOVSPodInOut
  elif [ $TUNNEL_MODE = "wireguard4" ] 
  then
    unwireOVSPodInOut       
  fi  
  }

function wireOVSPodInOut {
  echo running wireOVSPodInOut
  # retrieve the vethdevice name
  iflink=$(cat /sys/class/net/eth0/iflink)
  veth=$(nsenter -t 1 -n ip link | grep "$iflink: veth" | awk '{print $2}' | cut -d '@' -f 1)
  port=$(ovs-vsctl get Interface $veth ofport)
  mac=$(cat /sys/class/net/eth0/address)
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    echo cluster_cidr: $CLUSTER_CIDR , cidr: $cidr , port: $port , mac: $mac
  # table=0, priority=300,ip,nw_src=10.128.0.0/14, nw_dst=10.132.0.0/14 actions=output:<port_of_tunnel>
  # to modify the destination address: mod_dl_dst:mac
    ovs-ofctl add-flow br0 "table=0,priority=300,ip,nw_src=$CLUSTER_CIDR,nw_dst=$cidr,actions=mod_dl_dst:$mac,output:$port" --protocols=OpenFlow13
  #From remote tunnel to local network 
  # table=0, priority=300,ip,nw_src=10.132.0.0/14, nw_dst=10.128.0.0/14 action=goto_table:30
    ovs-ofctl add-flow br0 "table=0,priority=300,ip,in_port=$port,nw_src=$cidr,nw_dst=$CLUSTER_CIDR,action=goto_table:30" --protocols=OpenFlow13
  done
  }

function unwireOVSPodInOut {
  echo running unwireOVSPodInOut
  # retrieve the vethdevice name
  set +e
  iflink=$(cat /sys/class/net/eth0/iflink)
  veth=$(nsenter -t 1 -n ip link | grep "$iflink: veth" | awk '{print $2}' | cut -d '@' -f 1)
  port=$(ovs-vsctl get Interface $veth ofport)
  mac=$(cat /sys/class/net/eth0/address)
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    echo cluster_cidr: $CLUSTER_CIDR , cidr: $cidr , port: $port
  # table=0, priority=300,ip,nw_src=10.128.0.0/14, nw_dst=10.132.0.0/14 actions=output:<port_of_tunnel>
    ovs-ofctl del-flows br0 "table=0,priority=300,ip,nw_src=$CLUSTER_CIDR,nw_dst=$cidr,actions=mod_dl_dst:$mac,output:$port" --protocols=OpenFlow13
  #From remote tunnel to local network 
  # table=0, priority=300,ip,nw_src=10.132.0.0/14, nw_dst=10.128.0.0/14 action=goto_table:30
    ovs-ofctl del-flows br0 "table=0,priority=300,ip,in_port=$port,nw_src=$cidr,nw_dst=$CLUSTER_CIDR,action=goto_table:30" --protocols=OpenFlow13
  done
  set -e  
  }

function setupIPTables {

# wait untill the config file appears
  while [ ! -f $PEER_CONFIG ]
  do
    sleep 2
  done
  
  lines=$(cat $PEER_CONFIG)
  for line in $lines ; 
  do
    iptables -t nat -A INPUT -i eth0 -p udp --dport $TUNNEL_PORT -s ${line%-*} -j SNAT --to-source ${line#*-}:$TUNNEL_PORT
  done  
  
  }

function cleanupAndExit {
  cleanup
  exit 0
  }


cleanup  
trap cleanupAndExit TERM
setup
sleep infinity & wait $!
trap - TERM


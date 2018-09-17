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

set -o nounset
set -o errexit

## this is not supported in RHEL yet, the fou module is needed to support this 
function fouCleanup {
  echo running fouCleanup
  set +e
  ip a | grep $TUNNEL_DEV_NAME
  if [ $? = '0' ] 
  then
    ip addr del $TUNNEL_CIDR dev $TUNNEL_DEV_NAME  
    ip link delete $TUNNEL_DEV_NAME type ipip
    ip fou del port $TUNNEL_PORT
  fi  
  set -e
  }

function setupFouTunnel {
  echo running setupFouTunnel
  ip fou add port $TUNNEL_PORT ipproto 4
  ip link add name $TUNNEL_DEV_NAME type ipip remote $TUNNEL_REMOTE_PEER local $TUNNEL_LOCAL_PEER ttl 225 encap fou encap-sport \
    auto encap-dport $TUNNEL_PORT
  ip addr add $TUNNEL_CIDR dev $TUNNEL_DEV_NAME
  }

function setupSocat {
  echo running setupSocat
  # to debug add -d -d -d -d -D -v
  socat -d -d UDP:$TUNNEL_REMOTE_PEER:$TUNNEL_PORT,bind=$TUNNEL_LOCAL_PEER:$TUNNEL_PORT \
    TUN:$TUNNEL_CIDR,tun-name=$TUNNEL_DEV_NAME,iff-no-pi,tun-type=tun,iff-up &
  }

function cleanupSocat {
  echo running cleanupSocat
  set +e
  killall socat
  set -e
  }

function setupSocatcs {
  echo running setupSocatcs
  echo starting server
  socat -d -d UDP-RECV:$TUNNEL_PORT,bind=$TUNNEL_LOCAL_PEER TUN:$TUNNEL_CIDR,tun-name=$TUNNEL_DEV_NAME,iff-no-pi,tun-type=tun,iff-up &  
  echo starting client 
  socat -d -d UDP-SENDTO:$TUNNEL_REMOTE_PEER:$TUNNEL_PORT TUN,tun-name=$TUNNEL_DEV_NAME &  
  }

function cleanupSocatcs {
  echo running cleanupSocatcs
  set +e
  killall socat
  set -e  
  }

function setupWg2 {
  echo running setupwg2
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

function cleanupWg2 {
  echo running cleanupWg
  set +e
  ip a | grep $TUNNEL_DEV_NAME
  if [ $? = '0' ] 
  then  
    ip link set down dev $TUNNEL_DEV_NAME
    ip link delete dev $TUNNEL_DEV_NAME type wireguard
  fi  
  set -e     
  }

function setupWg {
  echo running setupwg
  ip link add dev $TUNNEL_DEV_NAME type wireguard
  ip link set $TUNNEL_DEV_NAME netns 1
  nsenter -t 1 -n wg setconf $TUNNEL_DEV_NAME $WIREGUARD_CONFIG  
  nsenter -t 1 -n ip link set up dev $TUNNEL_DEV_NAME
  }

function cleanupWg {
  echo running cleanupWg
  set +e
  nsenter -t 1 -n ip a | grep $TUNNEL_DEV_NAME
  if [ $? = '0' ] 
  then  
    nsenter -t 1 -n ip link set down dev $TUNNEL_DEV_NAME
    nsenter -t 1 -n ip link delete dev $TUNNEL_DEV_NAME type wireguard
  fi  
  set -e  
}


function setup {
  echo running setup
  setupIPTables
  if [ $TUNNEL_MODE = "fou" ] 
  then
    setupFouTunnel
  elif [ $TUNNEL_MODE = "socat" ] 
  then
    setupSocat
  elif [ $TUNNEL_MODE = "socatcs" ] 
  then
    setupSocatcs
  elif [ $TUNNEL_MODE = "wireguard" ] 
  then
    setupWg2
  fi  
  wireOVS2  
  }

function cleanup {
  echo running cleanup
  unwireOVS2
  if [ $TUNNEL_MODE = "fou" ] 
  then
    cleanupFouTunnel
  elif [ $TUNNEL_MODE = "socat" ] 
  then
    cleanupSocat
  elif [ $TUNNEL_MODE = "socatcs" ] 
  then
    cleanupSocatcs
  elif [ $TUNNEL_MODE = "wireguard" ] 
  then
    cleanupWg2
  fi  
  }   

function wireOVS2 {
  echo running wireOVS2
  # retrieve the vethdevice name
  iflink=$(cat /sys/class/net/eth0/iflink)
  veth=$(nsenter -t 1 -n ip link | grep $iflink: | awk '{print $2}' | cut -d '@' -f 1)
  port=$(ovs-vsctl get Interface $veth ofport)
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    echo cluster_cidr: $CLUSTER_CIDR , cidr: $cidr , port: $port
  # table=0, priority=300,ip,nw_src=10.128.0.0/14, nw_dst=10.132.0.0/14 actions=output:<port_of_tunnel>
    ovs-ofctl add-flow br0 "table=0,priority=300,ip,nw_src=$CLUSTER_CIDR,nw_dst=$cidr,actions=output:$port" --protocols=OpenFlow13
  #From remote tunnel to local network 
  # table=0, priority=300,ip,nw_src=10.132.0.0/14, nw_dst=10.128.0.0/14 action=goto_table:30
    ovs-ofctl add-flow br0 "table=0,priority=300,ip,in_port=$port,nw_src=$cidr,nw_dst=$CLUSTER_CIDR action=goto_table:30" --protocols=OpenFlow13
  done  
  }

function unwireOVS2 {
  echo running unwireOVS2
  # retrieve the vethdevice name
  set +e
  iflink=$(cat /sys/class/net/eth0/iflink)
  veth=$(nsenter -t 1 -n ip link | grep $iflink: | awk '{print $2}' | cut -d '@' -f 1)
  port=$(ovs-vsctl get Interface $veth ofport)
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    echo cluster_cidr: $CLUSTER_CIDR , cidr: $cidr , port: $port
  # table=0, priority=300,ip,nw_src=10.128.0.0/14, nw_dst=10.132.0.0/14 actions=output:<port_of_tunnel>
    ovs-ofctl del-flows br0 table=0,priority=300,ip,nw_src=$CLUSTER_CIDR,nw_dst=$cidr,actions=output:$port --protocols=OpenFlow13
  #From remote tunnel to local network 
  # table=0, priority=300,ip,nw_src=10.132.0.0/14, nw_dst=10.128.0.0/14 action=goto_table:30
    ovs-ofctl del-flows br0 table=0,priority=300,ip,nw_src=$cidr,nw_dst=$CLUSTER_CIDR action=goto_table:30 --protocols=OpenFlow13
  done
  set -e  
  }


function wireOVS {
  echo running wireOVS
  ovs-vsctl add-port br0 $TUNNEL_DEV_NAME  --  set  Interface  $TUNNEL_DEV_NAME type=internal 
  #tunnel <port_of_tunnel> determined by "ovs-ofctl show $TUNNEL_DEV_NAME --protocols=OpenFlow13"
  # TODO this might be better ovs-vsctl get Interface $TUNNEL_DEV_NAME ofport
  port=$(ovs-ofctl dump-ports-desc br0 --protocols=OpenFlow13 | grep $TUNNEL_DEV_NAME | awk '{print $1}' | cut -d'(' -f 1)
  echo port $port
  echo ext_cidr $TUNNEL_CIDRs
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    echo current cidr $cidr
  # table=0, priority=300,ip,nw_src=10.128.0.0/14, nw_dst=10.132.0.0/14 actions=output:<port_of_tunnel>
    ovs-ofctl add-flow br0 "table=0,priority=300,ip,nw_src=$CLUSTER_CIDR,nw_dst=$cidr,actions=output:$port" --protocols=OpenFlow13
  #From remote tunnel to local network 
  # table=0, priority=300,ip,nw_src=10.132.0.0/14, nw_dst=10.128.0.0/14 action=goto_table:30
    ovs-ofctl add-flow br0 "table=0,priority=300,ip,nw_src=$cidr,nw_dst=$CLUSTER_CIDR action=goto_table:30" --protocols=OpenFlow13
  done    
}

function unwireOVS {
  echo running unwireOVS
  #TODO remove flow rules
  set +e
  
  port=$(ovs-ofctl dump-ports-desc br0 --protocols=OpenFlow13 | grep sdn-tunnel | awk '{print $1}' | cut -d'(' -f 1)
  
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
  # table=0, priority=300,ip,nw_src=10.128.0.0/14, nw_dst=10.132.0.0/14 actions=output:<port_of_tunnel>
    ovs-ofctl del-flows br0 table=0,priority=300,ip,nw_src=$CLUSTER_CIDR,nw_dst=$cidr,actions=output:$port --protocols=OpenFlow13
  #From remote tunnel to local network 
  # table=0, priority=300,ip,nw_src=10.132.0.0/14, nw_dst=10.128.0.0/14 action=goto_table:30
    ovs-ofctl del-flows br0 table=0,priority=300,ip,nw_src=$cidr,nw_dst=$CLUSTER_CIDR action=goto_table:30 --protocols=OpenFlow13
  done
  
  ovs-vsctl list-ports br0 | grep $TUNNEL_DEV_NAME
  if [ $? = '0' ] 
  then
    ovs-vsctl del-port br0 $TUNNEL_DEV_NAME
  fi
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




cleanup  
trap cleanup TERM
setup
sleep infinity
trap - TERM


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

# this needs to run in the pod's namespace
function setupGre {
  echo running setupGre
  # wait untill the config file appears
  while [ ! -f $NODEIP_CIDR ]
  do
    sleep 2
  done

# format of the peer-config file:
# nodeIP-nodeCIDR
  
  lines=$(cat $NODEIP_CIDR)
  for line in $lines ; 
  do
    tunnel_suffix=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
    ip tunnel add tun-$tunnel_suffix mode gre remote ${line%-*}
    ip link set up tun-$tunnel_suffix
    ip route add ${line#*-} dev tun-$tunnel_suffix
  done 
}

function setupFouTunnel {
  echo running setupFouTunnel
  ip fou add port $TUNNEL_PORT ipproto 4
  ip link add name $TUNNEL_DEV_NAME type ipip remote $TUNNEL_REMOTE_PEER local $TUNNEL_LOCAL_PEER ttl 225 encap fou encap-sport \
    auto encap-dport $TUNNEL_PORT
  ip addr add $TUNNEL_CIDR dev $TUNNEL_DEV_NAME
  }

# all in node's network namespace
function setupWg5 {
  echo running setupwg5
  
  ovs-vsctl add-port br0 sdn-ext -- set Interface sdn-ext type=internal
  ip link set up dev sdn-ext
  
  ip link add dev $TUNNEL_DEV_NAME type wireguard
  ip link set $TUNNEL_DEV_NAME netns $$
  wg setconf $TUNNEL_DEV_NAME $WIREGUARD_CONFIG
  ip link set up dev $TUNNEL_DEV_NAME
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    ip route add $cidr dev $TUNNEL_DEV_NAME
  done
  
  #ip route add $CLUSTER_CIDR dev sdn-ext    
}

function cleanupWg5 {
  echo running cleanupWg5
  set +e

  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    ip route del $cidr dev $TUNNEL_DEV_NAME
  done
  #ip route del $CLUSTER_CIDR dev sdn-ext  
  
  ip link set down dev snd-ext
  ovs-vsctl del-port br0 sdn-ext   
  
  ip a | grep $TUNNEL_DEV_NAME
  if [ $? = '0' ] 
  then  
    ip link set down dev $TUNNEL_DEV_NAME
    ip link delete dev $TUNNEL_DEV_NAME type wireguard
  fi 
   
  set -e     
  }


# wg created in node's network namespace and moved to pod's network namespace

function setupWg4 {
  echo running setupwg4
  sysctl -w net.ipv4.ip_forward=1
  sysctl -w net.ipv4.conf.all.proxy_arp=1
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

# wire end of WG in the node's network namespace, the app end in the pod's network namespace

function setupWg2 {
  echo running setupwg
  ip link add dev $TUNNEL_DEV_NAME type wireguard
  ip link set $TUNNEL_DEV_NAME netns 1
  nsenter -t 1 -n wg setconf $TUNNEL_DEV_NAME $WIREGUARD_CONFIG  
  nsenter -t 1 -n ip link set up dev $TUNNEL_DEV_NAME
  }

function cleanupWg2 {
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
  
  if [ $TUNNEL_MODE = "fou" ] 
  then
    setupFouTunnel
    wireOVSPodInOut
  elif [ $TUNNEL_MODE = "gre" ] 
  then
    setupGre
    wireOVSPodIn    
  elif [ $TUNNEL_MODE = "wireguard1" ] 
  then
    setupIPTables
    setupWg1
    wireOVSWgInOut
  elif [ $TUNNEL_MODE = "wireguard2" ] 
  then
    setupIPTables
    setupWg2
    wireOVSWg2InOut
  elif [ $TUNNEL_MODE = "wireguard4" ] 
  then
    setupWg4
    wireOVSPodInOut
  elif [ $TUNNEL_MODE = "wireguard5" ] 
  then
    setupWg5
    wireOVSWg5In             
  fi   
  }

function cleanup {
  echo running cleanup

  if [ $TUNNEL_MODE = "fou" ] 
  then
    unwireOVSPodInOut
  elif [ $TUNNEL_MODE = "gre" ] 
  then
    unwireOVSPodIn
  elif [ $TUNNEL_MODE = "wireguard1" ] 
  then
    unwireOVSPodInOut
  elif [ $TUNNEL_MODE = "wireguard2" ] 
  then
    unwireOVSWg2InOut
    cleanupWg2
  elif [ $TUNNEL_MODE = "wireguard4" ] 
  then
    unwireOVSPodInOut
  elif [ $TUNNEL_MODE = "wireguard5" ] 
  then
    cleanupWg5
    unwireOVSWg5In       
  fi  
  }

function wireOVSPodIn {
  echo running wireOVSPodIn
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
  done
  }

function unwireOVSPodIn {
  echo running unwireOVSPodIn
  # retrieve the vethdevice name
  set +e
  iflink=$(cat /sys/class/net/eth0/iflink)
  veth=$(nsenter -t 1 -n ip link | grep "$iflink: veth" | awk '{print $2}' | cut -d '@' -f 1)
  port=$(ovs-vsctl get Interface $veth ofport)
  mac=$(cat /sys/class/net/eth0/address)
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    echo cluster_cidr: $CLUSTER_CIDR , cidr: $cidr , port: $port , mac: $mac
  # table=0, priority=300,ip,nw_src=10.128.0.0/14, nw_dst=10.132.0.0/14 actions=output:<port_of_tunnel>
    ovs-ofctl del-flows br0 "table=0,priority=300,ip,nw_src=$CLUSTER_CIDR,nw_dst=$cidr,actions=mod_dl_dst:$mac,output:$port" --protocols=OpenFlow13
  #From remote tunnel to local network 
  done
  set -e  
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

function wireOVSWg5In {
  echo running wireOVSWg5In
  # retrieve the vethdevice name
  out_port=$(ovs-vsctl get Interface sdn-ext ofport)
  in_port=$(ovs-vsctl get Interface tun0 ofport)
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    echo cluster_cidr: $CLUSTER_CIDR , cidr: $cidr , out_port: $out_port , in_port: $in_port
  # table=0, priority=300,ip,nw_src=10.128.0.0/14, nw_dst=10.132.0.0/14 actions=output:<port_of_tunnel>
    ovs-ofctl add-flow br0 "table=0,priority=300,ip,nw_src=$CLUSTER_CIDR,nw_dst=$cidr,actions=output:$out_port" --protocols=OpenFlow13
  #From remote tunnel to local network 
  # table=0, priority=300,ip,nw_src=10.132.0.0/14, nw_dst=10.128.0.0/14 action=goto_table:30
    ovs-ofctl add-flow br0 "table=0,priority=300,ip,in_port=$in_port,nw_src=$cidr,nw_dst=$CLUSTER_CIDR,action=goto_table:30" --protocols=OpenFlow13
  done  
  }

function unwireOVSWg5In {
  echo running unwireOVSWg5In
  # retrieve the vethdevice name
  set +e
  out_port=$(ovs-vsctl get Interface sdn-ext ofport)
  in_port=$(ovs-vsctl get Interface tun0 ofport)
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
    echo cluster_cidr: $CLUSTER_CIDR , cidr: $cidr , out_port: $out_port , in_port: $in_port
  # table=0, priority=300,ip,nw_src=10.128.0.0/14, nw_dst=10.132.0.0/14 actions=output:<port_of_tunnel>
    ovs-ofctl del-flows br0 "table=0,priority=300,ip,nw_src=$CLUSTER_CIDR,nw_dst=$cidr,actions=output:$out_port" --protocols=OpenFlow13
  #From remote tunnel to local network 
  # table=0, priority=300,ip,nw_src=10.132.0.0/14, nw_dst=10.128.0.0/14 action=goto_table:30
    ovs-ofctl del-flows br0 "table=0,priority=300,ip,in_port=$in_port,nw_src=$cidr,nw_dst=$CLUSTER_CIDR,action=goto_table:30" --protocols=OpenFlow13
  done
  set -e  
  }


function wireOVSWg2InOut {
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
    ovs-ofctl add-flow br0 "table=0,priority=300,ip,nw_src=$cidr,nw_dst=$CLUSTER_CIDR,action=goto_table:30" --protocols=OpenFlow13
  done    
}

function unwireOVSWg2InOut {
  echo running unwireOVS
  #TODO remove flow rules
  set +e
  
  port=$(ovs-ofctl dump-ports-desc br0 --protocols=OpenFlow13 | grep sdn-tunnel | awk '{print $1}' | cut -d'(' -f 1)
  
  for cidr in ${TUNNEL_CIDRs//,/ }
  do
  # table=0, priority=300,ip,nw_src=10.128.0.0/14, nw_dst=10.132.0.0/14 actions=output:<port_of_tunnel>
    ovs-ofctl del-flows br0 "table=0,priority=300,ip,nw_src=$CLUSTER_CIDR,nw_dst=$cidr,actions=output:$port" --protocols=OpenFlow13
  #From remote tunnel to local network 
  # table=0, priority=300,ip,nw_src=10.132.0.0/14, nw_dst=10.128.0.0/14 action=goto_table:30
    ovs-ofctl del-flows br0 "table=0,priority=300,ip,nw_src=$cidr,nw_dst=$CLUSTER_CIDR,action=goto_table:30" --protocols=OpenFlow13
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

function cleanupAndExit {
  cleanup
  exit 0
  }


cleanup  
trap cleanupAndExit TERM
setup
sleep infinity & wait $!
trap - TERM


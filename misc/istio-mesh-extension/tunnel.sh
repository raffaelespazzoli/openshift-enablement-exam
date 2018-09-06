#!/usr/bin/env bash

#### this script uses the following environment variables
# TUNNEL_PORT : the port used to establish the tunnel
# TUNNEL_DEV_NAME : the device used to establush the tunnel
# TUNNEL_REMOTE_PEER : the peer IP or VIP to which establish the tunnel 
# TUNNEL_LOCAL_PEER : the local IP to be used for the tunnel
# TUNNEL_CIDR : the CIDR that should be routed thoru this tunnel in x.x.x.x/x format
# TUNNEL_PRIVATE_KEY: the absolute location of the private key file
# TUNNEL_PEER_PUBLIC_KEY: the peer's public key
# TUNNEL_MODE: implementnation of the tunnel (fou, socat, socatcs, wireguard)

set -o nounset
set -o errexit

## this is not supported in RHEL yet, the fou module is needed to support this 
function fouCleanup {
  set +e
  ip addr del $TUNNEL_CIDR dev $TUNNEL_DEV_NAME  
  ip link delete $TUNNEL_DEV_NAME type ipip
  ip fou del port $TUNNEL_PORT
  set -e
  }

function setupFouTunnel {
  ip fou add port $TUNNEL_PORT ipproto 4
  ip link add name $TUNNEL_DEV_NAME type ipip remote $TUNNEL_REMOTE_PEER local $TUNNEL_LOCAL_PEER ttl 225 encap fou encap-sport auto encap-dport $TUNNEL_PORT
  ip addr add $TUNNEL_CIDR dev $TUNNEL_DEV_NAME
  }

function setupSocat {
  # to debug add -d -d -d -d -D -v
  socat UDP:$TUNNEL_REMOTE_PEER:$TUNNEL_PORT,bind=$TUNNEL_LOCAL_PEER:$TUNNEL_PORT \
  TUN:$TUNNEL_CIDR,tun-name=$TUNNEL_DEV_NAME,iff-no-pi,tun-type=tun,iff-up &
  # attach the tunnel device to the openvswitch bridge
  }

function cleanupSocat {
  echo cleaning up
  killall socat
  }

function setupSocatcs {
  echo starting server
  socat -d -d UDP-RECV:$TUNNEL_PORT,bind=$TUNNEL_LOCAL_PEER:$TUNNEL_PORT TUN:$TUNNEL_CIDR,tun-name=$TUNNEL_DEV_NAME,iff-no-pi,tun-type=tun,iff-up &  
  echo starting client 
  socat -d -d UDP-SENDTO:$TUNNEL_REMOTE_PEER:$TUNNEL_PORT TUN,tun-name=$TUNNEL_DEV_NAME &  
  }

function cleanupSocatcs {
  echo cleaning up
  killall socat  
  }

function setupWg {
  ip link add dev $TUNNEL_DEV_NAME type wireguard
  wg set $TUNNEL_DEV_NAME listen-port $TUNNEL:PORT end-point $TUNNEL_REMOTE_PEER:$TUNNEL_PORT allowed-ips $TUNNEL_CIDR private-key $TUNNEL_PRIVATE_KEY peer $TUNNEL_PEER_PUBLIC_KEY
  ip link set up dev $TUNNEL_DEV_NAME
  }

function cleanupWg {
  ip link set down dev $TUNNEL_DEV_NAME  
}


function setup {
  if [ $TUNNEL_MODE = fou ] then
    setupFouTunnel()
  elif [ $TUNNEL_MODE = socat ] then
    setupSocat()
  elif [ $TUNNEL_MODE = socatcs ] then
    setupSocatcs()
  elif [ $TUNNEL_MODE = wireguard ] then
    setupWg()
    
  wireOVS()  
  }

function cleanup {
  unwireOVS()
  if [ $TUNNEL_MODE = fou ] then
    cleanupFouTunnel()
  elif [ $TUNNEL_MODE = socat ] then
    cleanupSocat()
  elif [ $TUNNEL_MODE = socatcs ] then
    cleanupSocatcs()
  elif [ $TUNNEL_MODE = wireguard ] then
    cleanupWg()
  }   
}

function wireOVS {
  ovs-vsctl add-port br0 $TUNNEL_DEV_NAME
  #TODO add flow rules  
}

function unwireOVS{
  #TODO remove flow rules
  ovs-vsctl add-port br0 $TUNNEL_DEV_NAME  
}


cleanup  
trap cleanup TERM
setup
sleep inifinity
trap - TERM


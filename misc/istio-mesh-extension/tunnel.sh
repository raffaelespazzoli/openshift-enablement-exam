#!/bin/bash

#### this script uses the following environment variables
# TUNNEL_PORT : the port used to establish the tunnel
# TUNNEL_DEV_NAME : the device used to establush the tunnel
# TUNNEL_REMOTE_PEER : the peer IP or VIP to which establish the tunnel 
# TUNNEL_LOCAL_PEER : the local IP to be used for the tunnel
# TUNNEL_CIDR : the CIDR that should be routed thoru this tunnel in x.x.x.x/x format

set -o nounset
set -o errexit

## this is not supported in RHEL yet, the fou module is needed to support this 
#function cleanup {
#  set +e
#  ip addr del $TUNNEL_CIDR dev $TUNNEL_DEV_NAME  
#  ip link delete $TUNNEL_DEV_NAME type ipip
#  ip fou del port $TUNNEL_PORT
#  set -e
#  }

#function setupTunnel {
#  ip fou add port $TUNNEL_PORT ipproto 4
#  ip link add name $TUNNEL_DEV_NAME type ipip remote $TUNNEL_REMOTE_PEER local $TUNNEL_LOCAL_PEER ttl 225 encap fou encap-sport auto encap-dport $TUNNEL_PORT
#  ip addr add $TUNNEL_CIDR dev $TUNNEL_DEV_NAME
#  }

function setupTunnel {
  # to debug add -d -d -d -d -D -v
  socat UDP:$TUNNEL_REMOTE_PEER:$TUNNEL_PORT,bind=$TUNNEL_LOCAL_PEER:$TUNNEL_PORT \
  TUN:$TUNNEL_CIDR,tun-name=$TUNNEL_DEV_NAME,iff-no-pi,tun-type=tun,iff-up
  # attach the tunnel device to the openvswitch bridge
  }

function cleanup {
  echo cleaning up
  }

cleanup  
trap cleanup TERM
setupTunnel
sleep inifinity
trap - TERM


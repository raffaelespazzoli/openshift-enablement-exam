#!/bin/bash
set -e

: ${CLUSTER:=ceph}
: ${CEPH_CLUSTER_NETWORK:=${CEPH_PUBLIC_NETWORK}}
: ${CEPH_DAEMON:=${1}} # default daemon to first argument
: ${CEPH_GET_ADMIN_KEY:=0}
: ${HOSTNAME:=$(hostname -s)}
: ${MON_NAME:=${HOSTNAME}}
: ${NETWORK_AUTO_DETECT:=0}
: ${MDS_NAME:=mds-${HOSTNAME}}
: ${OSD_FORCE_ZAP:=0}
: ${OSD_JOURNAL_SIZE:=100}
: ${CRUSH_LOCATION:=root=default host=${HOSTNAME}}
: ${CEPHFS_CREATE:=0}
: ${CEPHFS_NAME:=cephfs}
: ${CEPHFS_DATA_POOL:=${CEPHFS_NAME}_data}
: ${CEPHFS_DATA_POOL_PG:=8}
: ${CEPHFS_METADATA_POOL:=${CEPHFS_NAME}_metadata}
: ${CEPHFS_METADATA_POOL_PG:=8}
: ${RGW_NAME:=${HOSTNAME}}
: ${RGW_ZONEGROUP:=}
: ${RGW_ZONE:=}
: ${RGW_CIVETWEB_PORT:=8080}
: ${RGW_REMOTE_CGI:=0}
: ${RGW_REMOTE_CGI_PORT:=9000}
: ${RGW_REMOTE_CGI_HOST:=0.0.0.0}
: ${RGW_USER:="cephnfs"}
: ${RESTAPI_IP:=0.0.0.0}
: ${RESTAPI_PORT:=5000}
: ${RESTAPI_BASE_URL:=/api/v0.1}
: ${RESTAPI_LOG_LEVEL:=warning}
: ${RESTAPI_LOG_FILE:=/var/log/ceph/ceph-restapi.log}
: ${KV_TYPE:=none} # valid options: consul, etcd or none
: ${KV_IP:=127.0.0.1}
: ${KV_PORT:=4001} # PORT 8500 for Consul
: ${GANESHA_OPTIONS:=""}
: ${GANESHA_EPOCH:=""} # For restarting

if [ ! -z "${KV_CA_CERT}" ]; then
	KV_TLS="--ca-cert=${KV_CA_CERT} --client-cert=${KV_CLIENT_CERT} --client-key=${KV_CLIENT_KEY}"
	CONFD_KV_TLS="-scheme=https -client-ca-keys=${KV_CA_CERT} -client-cert=${KV_CLIENT_CERT} -client-key=${KV_CLIENT_KEY}"
fi

CEPH_OPTS="--cluster ${CLUSTER}"
MOUNT_OPTS="-t xfs -o noatime,inode64"


####################
# COMMON FUNCTIONS #
####################

# ceph config file exists or die
function check_config {
  if [[ ! -e /etc/ceph/${CLUSTER}.conf ]]; then
    echo "ERROR- /etc/ceph/${CLUSTER}.conf must exist; get it from your existing mon"
    exit 1
  fi
}

# ceph admin key exists or die
function check_admin_key {
  if [[ ! -e /etc/ceph/${CLUSTER}.client.admin.keyring ]]; then
      echo "ERROR- /etc/ceph/${CLUSTER}.client.admin.keyring must exist; get it from your existing mon"
      exit 1
  fi
}

# Given two strings, return the length of the shared prefix
function prefix_length {
  local maxlen=${#1}
  for ((i=maxlen-1;i>=0;i--)); do
    if [[ "${1:0:i}" == "${2:0:i}" ]]; then
      echo $i
      return
    fi
  done
}

# create socket directory
function create_socket_dir {
  mkdir -p /var/run/ceph
  chown ceph. /var/run/ceph
}

# Calculate proper device names, given a device and partition number
function dev_part {
  if [[ -L ${1} ]]; then
    # This device is a symlink. Work out it's actual device
    local actual_device=$(readlink -f ${1})
    local bn=$(basename $1)
    if [[ "${ACTUAL_DEVICE:0-1:1}" == [0-9] ]]; then
      local desired_partition="${actual_device}p${2}"
    else
      local desired_partition="${actual_device}${2}"
    fi
    # Now search for a symlink in the directory of $1
    # that has the correct desired partition, and the longest
    # shared prefix with the original symlink
    local symdir=$(dirname $1)
    local link=""
    local pfxlen=0
    for option in $(ls $symdir); do
    if [[ $(readlink -f $symdir/$option) == $desired_partition ]]; then
      local optprefixlen=$(prefix_length $option $bn)
      if [[ $optprefixlen > $pfxlen ]]; then
        link=$symdir/$option
        pfxlen=$optprefixlen
      fi
    fi
    done
    if [[ $pfxlen -eq 0 ]]; then
      >&2 echo "Could not locate appropriate symlink for partition $2 of $1"
      exit 1
    fi
    echo "$link"
  elif [[ "${1:0-1:1}" == [0-9] ]]; then
    echo "${1}p${2}"
  else
    echo "${1}${2}"
  fi
}

function osd_trying_to_determine_scenario {
  if [ -z "${OSD_DEVICE}" ]; then
    echo "Bootstrapped OSD(s) found; using OSD directory"
    osd_directory
  elif $(parted --script ${OSD_DEVICE} print | egrep -sq '^ 1.*ceph data'); then
    echo "Bootstrapped OSD found; activating ${OSD_DEVICE}"
    osd_activate
  else
    echo "Device detected, assuming ceph-disk scenario is desired"
    echo "Preparing and activating ${OSD_DEVICE}"
    osd_disk
  fi
}


###########################
# CONFIGURATION GENERATOR #
###########################

# Load in the bootstrapping routines
# based on the data store
case "$KV_TYPE" in
   etcd|consul)
      source /config.kv.sh
      ;;
   *)
      source /config.static.sh
      ;;
esac


##########
# CONFIG #
##########
function kv {
	# Note the 'cas' command puts a value in the KV store if it is empty
	KEY="$1"
	shift
	VALUE="$*"
	echo "adding key ${KEY} with value ${VALUE} to KV store"
	kviator --kvstore=${KV_TYPE} --client=${KV_IP}:${KV_PORT} ${KV_TLS} cas ${CLUSTER_PATH}"${KEY}" "${VALUE}" || echo "value is already set"
}

function populate_kv {
    CLUSTER_PATH=ceph-config/${CLUSTER}
    case "$KV_TYPE" in
       etcd|consul)
          # if ceph.defaults found in /etc/ceph/ use that
          if [[ -e "/etc/ceph/ceph.defaults" ]]; then
            DEFAULTS_PATH="/etc/ceph/ceph.defaults"
          else
          # else use defaults
            DEFAULTS_PATH="/ceph.defaults"
          fi
          # read defaults file, grab line with key<space>value without comment #
          cat "$DEFAULTS_PATH" | grep '^.* .*' | grep -v '#' | while read line; do
            kv `echo $line`
          done
          ;;
       *)
          ;;
    esac
}


#######
# MON #
#######

function start_mon {
  if [[ ! -n "$CEPH_PUBLIC_NETWORK" && ${NETWORK_AUTO_DETECT} -eq 0 ]]; then
    echo "ERROR- CEPH_PUBLIC_NETWORK must be defined as the name of the network for the OSDs"
    exit 1
  fi

  if [[ ! -n "$MON_IP" && ${NETWORK_AUTO_DETECT} -eq 0 ]]; then
    echo "ERROR- MON_IP must be defined as the IP address of the monitor"
    exit 1
  fi

  if [ ${NETWORK_AUTO_DETECT} -ne 0 ]; then
    NIC_MORE_TRAFFIC=$(grep -vE "lo:|face|Inter" /proc/net/dev | sort -n -k 2 | tail -1 | awk '{ sub (":", "", $1); print $1 }')
    if command -v ip; then
      if [ ${NETWORK_AUTO_DETECT} -eq 1 ]; then
        MON_IP=$(ip -6 -o a s $NIC_MORE_TRAFFIC | awk '{ sub ("/..", "", $4); print $4 }')
        if [ -z "$MON_IP" ]; then
          MON_IP=$(ip -4 -o a s $NIC_MORE_TRAFFIC | awk '{ sub ("/..", "", $4); print $4 }')
          CEPH_PUBLIC_NETWORK=$(ip r | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[0-9]\{1,2\}' | head -1)
        fi
      elif [ ${NETWORK_AUTO_DETECT} -eq 4 ]; then
        MON_IP=$(ip -4 -o a s $NIC_MORE_TRAFFIC | awk '{ sub ("/..", "", $4); print $4 }')
        CEPH_PUBLIC_NETWORK=$(ip r | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[0-9]\{1,2\}' | head -1)
      elif [ ${NETWORK_AUTO_DETECT} -eq 6 ]; then
        MON_IP=$(ip -6 -o a s $NIC_MORE_TRAFFIC | awk '{ sub ("/..", "", $4); print $4 }')
        CEPH_PUBLIC_NETWORK=$(ip r | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[0-9]\{1,2\}' | head -1)
      fi
    # best effort, only works with ipv4
    # it is tough to find the ip from the nic only using /proc
    # so we just take on of the addresses available
    # which is fairely safe given that containers usually have a single nic
    else
      MON_IP=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' /proc/net/fib_trie | grep -vEw "^127|255$|0$" | head -1)
      CEPH_PUBLIC_NETWORK=$(grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/[0-9]\{1,2\}' /proc/net/fib_trie | grep -vE "^127|^0" | head -1)
    fi
  fi

  if [[ -z "$MON_IP" || -z "$CEPH_PUBLIC_NETWORK" ]]; then
    echo "ERROR- it looks like we have not been able to discover the network settings"
    exit 1
  fi

  # get_mon_config is also responsible for bootstrapping the
  # cluster, if necessary
  get_mon_config
  create_socket_dir

  # If we don't have a monitor keyring, this is a new monitor
  if [ ! -e /var/lib/ceph/mon/${CLUSTER}-${MON_NAME}/keyring ]; then

    if [ ! -e /etc/ceph/${CLUSTER}.mon.keyring ]; then
      echo "ERROR- /etc/ceph/${CLUSTER}.mon.keyring must exist.  You can extract it from your current monitor by running 'ceph auth get mon. -o /etc/ceph/${CLUSTER}.mon.keyring' or use a KV Store"
      exit 1
    fi

    if [ ! -e /etc/ceph/monmap-${CLUSTER} ]; then
      echo "ERROR- /etc/ceph/monmap-${CLUSTER} must exist.  You can extract it from your current monitor by running 'ceph mon getmap -o /etc/ceph/monmap-<cluster>' or use a KV Store"
      exit 1
    fi

    # Testing if it's not the first monitor, if one key doesn't exist we assume none of them exist
    ceph-authtool /tmp/${CLUSTER}.mon.keyring --create-keyring --import-keyring /etc/ceph/${CLUSTER}.client.admin.keyring
    ceph-authtool /tmp/${CLUSTER}.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/${CLUSTER}.keyring
    ceph-authtool /tmp/${CLUSTER}.mon.keyring --import-keyring /var/lib/ceph/bootstrap-mds/${CLUSTER}.keyring
    ceph-authtool /tmp/${CLUSTER}.mon.keyring --import-keyring /var/lib/ceph/bootstrap-rgw/${CLUSTER}.keyring
    ceph-authtool /tmp/${CLUSTER}.mon.keyring --import-keyring /etc/ceph/${CLUSTER}.mon.keyring
    chown ceph. /tmp/${CLUSTER}.mon.keyring

    # Make the monitor directory
    mkdir -p /var/lib/ceph/mon/${CLUSTER}-${MON_NAME}
    chown ceph. /var/lib/ceph/mon/${CLUSTER}-${MON_NAME}

    # Prepare the monitor daemon's directory with the map and keyring
    ceph-mon --setuser ceph --setgroup ceph --mkfs -i ${MON_NAME} --monmap /etc/ceph/monmap-${CLUSTER} --keyring /tmp/${CLUSTER}.mon.keyring --mon-data /var/lib/ceph/mon/${CLUSTER}-${MON_NAME}

    # Clean up the temporary key
    rm /tmp/${CLUSTER}.mon.keyring
  fi

  echo "SUCCESS"
  # start MON
  exec /usr/bin/ceph-mon ${CEPH_OPTS} -d -i ${MON_NAME} --public-addr "${MON_IP}:6789" --setuser ceph --setgroup ceph
}


################
# OSD (common) #
################

function start_osd {
  get_config
  check_config
  create_socket_dir

  if [ ${CEPH_GET_ADMIN_KEY} -eq "1" ]; then
    get_admin_key
    check_admin_key
  fi

  case "$OSD_TYPE" in
    directory)
      osd_directory
      ;;
    disk)
      osd_disk
      ;;
    prepare)
      osd_disk_prepare
      ;;
    activate)
      osd_activate
      ;;
    activate_journal)
      osd_activate_journal
      ;;
    *)
      osd_trying_to_determine_scenario
      ;;
  esac
}


#################
# OSD_DIRECTORY #
#################

function osd_directory {
  if [[ ! -d /var/lib/ceph/osd ]]; then
    echo "ERROR- could not find the osd directory, did you bind mount the OSD data directory?"
    echo "ERROR- use -v <host_osd_data_dir>:/var/lib/ceph/osd"
    exit 1
  fi

  # make sure ceph owns the directory
  chown ceph. /var/lib/ceph/osd

  # check if anything is there, if not create an osd with directory
  if [[ -n "$(find /var/lib/ceph/osd -prune -empty)" ]]; then
    echo "Creating osd with ceph --cluster ${CLUSTER} osd create"
    OSD_ID=$(ceph --cluster ${CLUSTER} osd create)
    if [ "$OSD_ID" -eq "$OSD_ID" ] 2>/dev/null; then
        echo "OSD created with ID: ${OSD_ID}"
    else
      echo "OSD creation failed: ${OSD_ID}"
      exit 1
    fi

    # create the folder and own it
    mkdir -p /var/lib/ceph/osd/${CLUSTER}-${OSD_ID}
    chown ceph. /var/lib/ceph/osd/${CLUSTER}-${OSD_ID}
    echo "created folder /var/lib/ceph/osd/${CLUSTER}-${OSD_ID}"
  fi

  for OSD_ID in $(ls /var/lib/ceph/osd |  awk 'BEGIN { FS = "-" } ; { print $2 }'); do
    if [ -n "${JOURNAL_DIR}" ]; then
       OSD_J="${JOURNAL_DIR}/journal.${OSD_ID}"
       chown -R ceph. ${JOURNAL_DIR}
    else
       if [ -n "${JOURNAL}" ]; then
          OSD_J=${JOURNAL}
          chown -R ceph. $(dirname ${JOURNAL_DIR})
       else
          OSD_J=/var/lib/ceph/osd/${CLUSTER}-${OSD_ID}/journal
       fi
    fi

    # Check to see if our OSD has been initialized
    if [ ! -e /var/lib/ceph/osd/${CLUSTER}-${OSD_ID}/keyring ]; then
      chown ceph. /var/lib/ceph/osd/${CLUSTER}-${OSD_ID}
      # Create OSD key and file structure
      ceph-osd ${CEPH_OPTS} -i $OSD_ID --mkfs --mkkey --mkjournal --osd-journal ${OSD_J} --setuser ceph --setgroup ceph

      if [ ! -e /var/lib/ceph/bootstrap-osd/${CLUSTER}.keyring ]; then
        echo "ERROR- /var/lib/ceph/bootstrap-osd/${CLUSTER}.keyring must exist. You can extract it from your current monitor by running 'ceph auth get client.bootstrap-osd -o /var/lib/ceph/bootstrap-osd/${CLUSTER}.keyring'"
        exit 1
      fi

      timeout 10 ceph ${CEPH_OPTS} --name client.bootstrap-osd --keyring /var/lib/ceph/bootstrap-osd/${CLUSTER}.keyring health || exit 1

      # Add the OSD key
      ceph ${CEPH_OPTS} --name client.bootstrap-osd --keyring /var/lib/ceph/bootstrap-osd/${CLUSTER}.keyring auth add osd.${OSD_ID} -i /var/lib/ceph/osd/${CLUSTER}-${OSD_ID}/keyring osd 'allow *' mon 'allow profile osd'  || echo $1
      echo "done adding key"
      chown ceph. /var/lib/ceph/osd/${CLUSTER}-${OSD_ID}/keyring
      chmod 0600 /var/lib/ceph/osd/${CLUSTER}-${OSD_ID}/keyring

      # Add the OSD to the CRUSH map
      if [ ! -n "${HOSTNAME}" ]; then
        echo "HOSTNAME not set; cannot add OSD to CRUSH map"
        exit 1
      fi
      OSD_WEIGHT=$(df -P -k /var/lib/ceph/osd/${CLUSTER}-$OSD_ID/ | tail -1 | awk '{ d= $2/1073741824 ; r = sprintf("%.2f", d); print r }')
      ceph ${CEPH_OPTS} --name=osd.${OSD_ID} --keyring=/var/lib/ceph/osd/${CLUSTER}-${OSD_ID}/keyring osd crush create-or-move -- ${OSD_ID} ${OSD_WEIGHT} ${CRUSH_LOCATION}
    fi

    echo "SUCCESS"
    echo "store-daemon: starting daemon on ${HOSTNAME}..."
    exec ceph-osd ${CEPH_OPTS} -f -i ${OSD_ID} --osd-journal ${OSD_J} -k /var/lib/ceph/osd/${CLUSTER}-${OSD_ID}/keyring

  done
}


#########################
# OSD_CEPH_DISK_PREPARE #
#########################

function osd_disk_prepare {
  if [[ -z "${OSD_DEVICE}" ]];then
    echo "ERROR- You must provide a device to build your OSD ie: /dev/sdb"
    exit 1
  fi

  if [ ! -e /var/lib/ceph/bootstrap-osd/${CLUSTER}.keyring ]; then
    echo "ERROR- /var/lib/ceph/bootstrap-osd/${CLUSTER}.keyring must exist. You can extract it from your current monitor by running 'ceph auth get client.bootstrap-osd -o /var/lib/ceph/bootstrap-osd/${CLUSTER}.keyring'"
    exit 1
  fi

  timeout 10 ceph ${CEPH_OPTS} --name client.bootstrap-osd --keyring /var/lib/ceph/bootstrap-osd/${CLUSTER}.keyring health || exit 1

  mkdir -p /var/lib/ceph/osd
  chown ceph. /var/lib/ceph/osd

  # TODO:
  # -  add device format check (make sure only one device is passed

  if [[ "$(parted --script ${OSD_DEVICE} print | egrep '^ 1.*ceph data')" && ${OSD_FORCE_ZAP} -ne "1" ]]; then
    echo "ERROR- It looks like ${OSD_DEVICE} is an OSD, set OSD_FORCE_ZAP=1 to use this device anyway and zap its content"
    echo "You can also use the zap_device scenario on the appropriate device to zap it"
    exit 1
  elif [[ "$(parted --script ${OSD_DEVICE} print | egrep '^ 1.*ceph data')" && ${OSD_FORCE_ZAP} -eq "1" ]]; then
    echo "It looks like ${OSD_DEVICE} is an OSD, however OSD_FORCE_ZAP is enabled so we are zapping the device anyway"
    ceph-disk -v zap ${OSD_DEVICE}
  fi

  if [[ ! -z "${OSD_JOURNAL}" ]]; then
    ceph-disk -v prepare ${CEPH_OPTS} ${OSD_DEVICE} ${OSD_JOURNAL}
    chown ceph. ${OSD_JOURNAL}
  else
    ceph-disk -v prepare ${CEPH_OPTS} ${OSD_DEVICE}
    chown ceph. $(dev_part ${OSD_DEVICE} 2)
  fi
}


#################
# OSD_CEPH_DISK #
#################
function osd_disk {
  osd_disk_prepare
  osd_activate
}


##########################
# OSD_CEPH_DISK_ACTIVATE #
##########################

function osd_activate {
  if [[ -z "${OSD_DEVICE}" ]];then
    echo "ERROR- You must provide a device to build your OSD ie: /dev/sdb"
    exit 1
  fi

  mkdir -p /var/lib/ceph/osd
  chown ceph. /var/lib/ceph/osd
  # resolve /dev/disk/by-* names
  ACTUAL_OSD_DEVICE=$(readlink -f ${OSD_DEVICE})
  # wait till partition exists then activate it
  if [[ ! -z "${OSD_JOURNAL}" ]]; then
    timeout 10  bash -c "while [ ! -e ${OSD_DEVICE} ]; do sleep 1; done"
    chown ceph. ${OSD_JOURNAL}
    ceph-disk -v --setuser ceph --setgroup disk activate $(dev_part ${OSD_DEVICE} 1)
    OSD_ID=$(ceph-disk list | grep "$(dev_part ${ACTUAL_OSD_DEVICE} 1) ceph data" | awk -F, '{print $4}' | awk -F. '{print $2}')
  else
    timeout 10  bash -c "while [ ! -e $(dev_part ${OSD_DEVICE} 1) ]; do sleep 1; done"
    chown ceph. $(dev_part ${OSD_DEVICE} 2)
    ceph-disk -v --setuser ceph --setgroup disk activate $(dev_part ${OSD_DEVICE} 1)
    OSD_ID=$(ceph-disk list | grep "$(dev_part ${ACTUAL_OSD_DEVICE} 1) ceph data" | awk -F, '{print $4}' | awk -F. '{print $2}')
  fi
  OSD_WEIGHT=$(df -P -k /var/lib/ceph/osd/${CLUSTER}-$OSD_ID/ | tail -1 | awk '{ d= $2/1073741824 ; r = sprintf("%.2f", d); print r }')
  ceph ${CEPH_OPTS} --name=osd.${OSD_ID} --keyring=/var/lib/ceph/osd/${CLUSTER}-${OSD_ID}/keyring osd crush create-or-move -- ${OSD_ID} ${OSD_WEIGHT} ${CRUSH_LOCATION}

  # ceph-disk activiate has exec'ed /usr/bin/ceph-osd ${CEPH_OPTS} -f -i ${OSD_ID}
  # wait till docker stop or ceph-osd is killed
  OSD_PID=$(ps -ef |grep ceph-osd |grep osd.${OSD_ID} |awk '{print $2}')
  if [ -n "${OSD_PID}" ]; then
      echo "OSD (PID ${OSD_PID}) is running, waiting till it exits"
      while [ -e /proc/${OSD_PID} ]; do sleep 1;done
  else
      echo "SUCCESS"
      exec /usr/bin/ceph-osd ${CEPH_OPTS} -f -i ${OSD_ID} --setuser ceph --setgroup disk
  fi
}


##########################
# OSD_ACTIVATE_JOURNAL   #
##########################

function osd_activate_journal {
  if [[ -z "${OSD_JOURNAL}" ]];then
    echo "ERROR- You must provide a device to build your OSD journal ie: /dev/sdb2"
    exit 1
  fi

  # wait till partition exists
  timeout 10  bash -c "while [ ! -e ${OSD_JOURNAL} ]; do sleep 1; done"

  mkdir -p /var/lib/ceph/osd
  chown ceph. /var/lib/ceph/osd
  chown ceph. ${OSD_JOURNAL}
  ceph-disk -v --setuser ceph --setgroup disk activate-journal ${OSD_JOURNAL}

  OSD_ID=$(cat /var/lib/ceph/osd/$(ls -ltr /var/lib/ceph/osd/ | tail -n1 | awk -v pattern="$CLUSTER" '$0 ~ pattern {print $9}')/whoami)
  OSD_WEIGHT=$(df -P -k /var/lib/ceph/osd/${CLUSTER}-$OSD_ID/ | tail -1 | awk '{ d= $2/1073741824 ; r = sprintf("%.2f", d); print r }')
  ceph ${CEPH_OPTS} --name=osd.${OSD_ID} --keyring=/var/lib/ceph/osd/${CLUSTER}-${OSD_ID}/keyring osd crush create-or-move -- ${OSD_ID} ${OSD_WEIGHT} ${CRUSH_LOCATION}

  # ceph-disk activiate has exec'ed /usr/bin/ceph-osd ${CEPH_OPTS} -f -i ${OSD_ID}
  # wait till docker stop or ceph-osd is killed
  OSD_PID=$(ps -ef |grep ceph-osd |grep osd.${OSD_ID} |awk '{print $2}')
  if [ -n "${OSD_PID}" ]; then
      echo "OSD (PID ${OSD_PID}) is running, waiting till it exits"
      while [ -e /proc/${OSD_PID} ]; do sleep 1;done
  else
      echo "SUCCESS"
      exec /usr/bin/ceph-osd ${CEPH_OPTS} -f -i ${OSD_ID} --setuser ceph --setgroup disk
  fi
}


#######
# MDS #
#######

function start_mds {
  get_config
  check_config
  create_socket_dir

  # Check to see if we are a new MDS
  if [ ! -e /var/lib/ceph/mds/${CLUSTER}-${MDS_NAME}/keyring ]; then

     mkdir -p /var/lib/ceph/mds/${CLUSTER}-${MDS_NAME}
     chown ceph. /var/lib/ceph/mds/${CLUSTER}-${MDS_NAME}

    if [ -e /etc/ceph/${CLUSTER}.client.admin.keyring ]; then
       KEYRING_OPT="--name client.admin --keyring /etc/ceph/${CLUSTER}.client.admin.keyring"
    elif [ -e /var/lib/ceph/bootstrap-mds/${CLUSTER}.keyring ]; then
       KEYRING_OPT="--name client.bootstrap-mds --keyring /var/lib/ceph/bootstrap-mds/${CLUSTER}.keyring"
    else
      echo "ERROR- Failed to bootstrap MDS: could not find admin or bootstrap-mds keyring.  You can extract it from your current monitor by running 'ceph auth get client.bootstrap-mds -o /var/lib/ceph/bootstrap-mds/${CLUSTER}.keyring'"
      exit 1
    fi

    timeout 10 ceph ${CEPH_OPTS} $KEYRING_OPT health || exit 1

    # Generate the MDS key
    ceph ${CEPH_OPTS} $KEYRING_OPT auth get-or-create mds.$MDS_NAME osd 'allow rwx' mds 'allow' mon 'allow profile mds' -o /var/lib/ceph/mds/${CLUSTER}-${MDS_NAME}/keyring
    chown ceph. /var/lib/ceph/mds/${CLUSTER}-${MDS_NAME}/keyring
    chmod 600 /var/lib/ceph/mds/${CLUSTER}-${MDS_NAME}/keyring

  fi

  # NOTE (leseb): having the admin keyring is really a security issue
  # If we need to bootstrap a MDS we should probably create the following on the monitors
  # I understand that this handy to do this here
  # but having the admin key inside every container is a concern

  # Create the Ceph filesystem, if necessary
  if [ $CEPHFS_CREATE -eq 1 ]; then

    get_admin_key
    check_admin_key

    if [[ "$(ceph fs ls | grep -c name:.${CEPHFS_NAME},)" -eq "0" ]]; then
       # Make sure the specified data pool exists
       if ! ceph ${CEPH_OPTS} osd pool stats ${CEPHFS_DATA_POOL} > /dev/null 2>&1; then
          ceph ${CEPH_OPTS} osd pool create ${CEPHFS_DATA_POOL} ${CEPHFS_DATA_POOL_PG}
       fi

       # Make sure the specified metadata pool exists
       if ! ceph ${CEPH_OPTS} osd pool stats ${CEPHFS_METADATA_POOL} > /dev/null 2>&1; then
          ceph ${CEPH_OPTS} osd pool create ${CEPHFS_METADATA_POOL} ${CEPHFS_METADATA_POOL_PG}
       fi

       ceph ${CEPH_OPTS} fs new ${CEPHFS_NAME} ${CEPHFS_METADATA_POOL} ${CEPHFS_DATA_POOL}
    fi
  fi

  echo "SUCCESS"
  # NOTE: prefixing this with exec causes it to die (commit suicide)
  /usr/bin/ceph-mds ${CEPH_OPTS} -d -i ${MDS_NAME} --setuser ceph --setgroup ceph
}


#######
# RGW #
#######

function start_rgw {
  get_config
  check_config
  create_socket_dir

  if [ ${CEPH_GET_ADMIN_KEY} -eq "1" ]; then
    get_admin_key
    check_admin_key
  fi

  # Check to see if our RGW has been initialized
  if [ ! -e /var/lib/ceph/radosgw/${RGW_NAME}/keyring ]; then

    mkdir -p /var/lib/ceph/radosgw/${RGW_NAME}
    chown ceph. /var/lib/ceph/radosgw/${RGW_NAME}

    if [ ! -e /var/lib/ceph/bootstrap-rgw/${CLUSTER}.keyring ]; then
      echo "ERROR- /var/lib/ceph/bootstrap-rgw/${CLUSTER}.keyring must exist. You can extract it from your current monitor by running 'ceph auth get client.bootstrap-rgw -o /var/lib/ceph/bootstrap-rgw/${CLUSTER}.keyring'"
      exit 1
    fi

    timeout 10 ceph ${CEPH_OPTS} --name client.bootstrap-rgw --keyring /var/lib/ceph/bootstrap-rgw/${CLUSTER}.keyring health || exit 1

    # Generate the RGW key
    ceph ${CEPH_OPTS} --name client.bootstrap-rgw --keyring /var/lib/ceph/bootstrap-rgw/${CLUSTER}.keyring auth get-or-create client.rgw.${RGW_NAME} osd 'allow rwx' mon 'allow rw' -o /var/lib/ceph/radosgw/${RGW_NAME}/keyring
    chown ceph. /var/lib/ceph/radosgw/${RGW_NAME}/keyring
    chmod 0600 /var/lib/ceph/radosgw/${RGW_NAME}/keyring
  fi

  echo "SUCCESS"
  if [ "$RGW_REMOTE_CGI" -eq 1 ]; then
    /usr/bin/radosgw -d ${CEPH_OPTS} -n client.rgw.${RGW_NAME} -k /var/lib/ceph/radosgw/$RGW_NAME/keyring --rgw-socket-path="" --rgw-zonegroup="$RGW_ZONEGROUP" --rgw-zone="$RGW_ZONE" --rgw-frontends="fastcgi socket_port=$RGW_REMOTE_CGI_PORT socket_host=$RGW_REMOTE_CGI_HOST" --setuser ceph --setgroup ceph
  else
    /usr/bin/radosgw -d ${CEPH_OPTS} -n client.rgw.${RGW_NAME} -k /var/lib/ceph/radosgw/$RGW_NAME/keyring --rgw-socket-path="" --rgw-zonegroup="$RGW_ZONEGROUP" --rgw-zone="$RGW_ZONE" --rgw-frontends="civetweb port=$RGW_CIVETWEB_PORT" --setuser ceph --setgroup ceph
  fi
}

function create_rgw_user {

  # Check to see if our RGW has been initialized
  if [ ! -e /var/lib/ceph/radosgw/keyring ]; then
    echo "ERROR- /var/lib/ceph/radosgw/keyring must exist. Please get it from your Rados Gateway"
    exit 1
  fi

  mkdir -p "/var/lib/ceph/radosgw/${RGW_NAME}"
  mv /var/lib/ceph/radosgw/keyring /var/lib/ceph/radosgw/${RGW_NAME}/keyring

  if [ -z "${RGW_USER_SECRET_KEY}" ]; then
    radosgw-admin user create --uid=${RGW_USER} --display-name="RGW ${RGW_USER} User" -c /etc/ceph/${CLUSTER}.conf
  else
    radosgw-admin user create --uid=${RGW_USER} --access-key=${RGW_USER_ACCESS_KEY} --secret=${RGW_USER_SECRET_KEY} --display-name="RGW ${RGW_USER} User" -c /etc/ceph/${CLUSTER}.conf
  fi
}


###########
# RESTAPI #
###########

function start_restapi {
  get_config
  check_config

  # Ensure we have the admin key
  get_admin_key
  check_admin_key

  # Check to see if we need to add a [client.restapi] section; add, if necessary
  if [[ ! "$(egrep "\[client.restapi\]" /etc/ceph/${CLUSTER}.conf)" ]]; then
    cat <<ENDHERE >>/etc/ceph/${CLUSTER}.conf

[client.restapi]
  public addr = ${RESTAPI_IP}:${RESTAPI_PORT}
  restapi base url = ${RESTAPI_BASE_URL}
  restapi log level = ${RESTAPI_LOG_LEVEL}
  log file = ${RESTAPI_LOG_FILE}
ENDHERE
  fi

  echo "SUCCESS"
  # start ceph-rest-api
  exec /usr/bin/ceph-rest-api ${CEPH_OPTS} -n client.admin

}


###########
# GANESHA #
###########

function start_rpc {
  rpcbind || return 0
  rpc.statd -L || return 0
  rpc.idmapd || return 0

}

function start_nfs {
  get_config
  check_config

  # Ensure we have the admin key
  #get_admin_key
  #check_admin_key

  # Init RPC
  start_rpc

  echo "SUCCESS"

  # start nfs
  exec /usr/bin/ganesha.nfsd -F ${GANESHA_OPTIONS} ${GANESHA_EPOCH}

}


##############
# RBD MIRROR #
##############

function start_rbd_mirror {
  get_config
  check_config
  create_socket_dir

  # ensure we have the admin key
  get_admin_key
  check_admin_key

  echo "SUCCESS"

  # start rbd-mirror
  exec /usr/bin/rbd-mirror ${CEPH_OPTS} -d --setuser ceph --setgroup ceph

}


##############
# ZAP DEVICE #
##############

function zap_device {
  if [[ -z ${OSD_DEVICE} ]]; then
    echo "Please provide a device to zap!"
    echo "ie: '-e OSD_DEVICE=/dev/sdb'"
    exit 1
  else
    ceph-disk -v zap ${OSD_DEVICE}
  fi
}


###############
# CEPH_DAEMON #
###############

# Normalize DAEMON to lowercase
CEPH_DAEMON=$(echo ${CEPH_DAEMON} |tr '[:upper:]' '[:lower:]')

# If we are given a valid first argument, set the
# CEPH_DAEMON variable from it
case "$CEPH_DAEMON" in
  populate_kvstore)
    echo "kv store is not supported"
    ;;
  mds)
    start_mds
    ;;
  mon)
    start_mon
    ;;
  osd)
    start_osd
    ;;
  osd_directory)
    OSD_TYPE="directory"
    start_osd
    ;;
  osd_ceph_disk)
    OSD_TYPE="disk"
    start_osd
    ;;
  osd_ceph_disk_prepare)
    OSD_TYPE="prepare"
    start_osd
    ;;
  osd_ceph_disk_activate)
    OSD_TYPE="activate"
    start_osd
    ;;
  osd_ceph_activate_journal)
    OSD_TYPE="activate_journal"
    start_osd
    ;;
  rgw)
    start_rgw
    ;;
  rgw_user)
    create_rgw_user
    ;;
  restapi)
    start_restapi
    ;;
  rbd_mirror)
    start_rbd_mirror
    ;;
  zap_device)
    zap_device
    ;;
  nfs)
    start_nfs
    ;;
  *)
  if [ ! -n "$CEPH_DAEMON" ]; then
    echo "ERROR- One of CEPH_DAEMON or a daemon parameter must be defined as the name "
    echo "of the daemon you want to deploy."
    echo "Valid values for CEPH_DAEMON are MON, OSD, OSD_DIRECTORY, OSD_CEPH_DISK, OSD_CEPH_DISK_PREPARE, OSD_CEPH_DISK_ACTIVATE, OSD_CEPH_ACTIVATE_JOURNAL, MDS, RGW, RESTAPI, NFS, ZAP_DEVICE, RBD_MIRROR, RGW_USER, NFS"
    echo "Valid values for the daemon parameter are mon, osd, osd_directory, osd_ceph_disk, osd_ceph_disk_prepare, osd_ceph_disk_activate, osd_ceph_activate_journal, mds, rgw, restapi, nfs, zap_device, rbd_mirror, rgw_user, nfs"
    exit 1
  fi
  ;;
esac

exit 0

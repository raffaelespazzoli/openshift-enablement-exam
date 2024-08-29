https://github.com/oracle/docker-images


variables:


export HEALTHCHECK_INTERVAL=30s
export HEALTHCHECK_TIMEOUT=3s
export HEALTHCHECK_RETRIES=240
export DNS_CONTAINER_NAME=rac-dnsserver
export DNS_HOST_NAME=rac-dns
export DNS_IMAGE_NAME="oracle/rac-dnsserver:latest"
export DNS_DOMAIN="example.com"
export RAC_NODE_NAME_PREFIXP="racnodep"
export DNS_PUBLIC_IP=172.16.1.25
export DNS_PRIVATE_IP=192.168.17.25
export RACNODE1_CONTAINER_NAME=racnodep1
export RACNODE1_HOST_NAME=racnodep1
export RACNODE_IMAGE_NAME="localhost/oracle/database-rac:21.3.0-21.13.0"
export RACNODE1_NODE_VIP=172.16.1.200
export RACNODE1_VIP_HOSTNAME="racnodep1-vip"
export RACNODE1_PRIV_IP=192.168.17.170
export RACNODE1_PRIV_HOSTNAME="racnodep1-priv"
export RACNODE1_PUBLIC_IP=172.16.1.170
export RACNODE1_PUBLIC_HOSTNAME="racnodep1"
export PUBLIC_NETWORK_NAME="rac_pub1_nw"
export PUBLIC_NETWORK_SUBNET="172.16.1.0/24"
export PRIVATE_NETWORK_NAME="rac_priv1_nw"
export PRIVATE_NETWORK_SUBNET="192.168.17.0/24"
export INSTALL_NODE=racnodep1
export SCAN_NAME="racnodepc1-scan"
export SCAN_IP=172.16.1.236
export ASM_DISCOVERY_DIR="/dev/"
export PWD_KEY="pwd.key"
export ASM_DISK1="/dev/oracleoci/oraclevdd"
export ASM_DISK2="/dev/oracleoci/oraclevde"
export ASM_DEVICE1="/dev/asm-disk1"
export ASM_DEVICE2="/dev/asm-disk2"
export ASM_DEVICE_LIST="${ASM_DEVICE1},${ASM_DEVICE2}"
export ORACLE_SID="ORCLCDB"
export CMAN_HOSTNAME="racnodepc1-cman"
export CMAN_PUBLIC_IP=172.16.1.15
export COMMON_OS_PWD_FILE="common_os_pwdfile.enc"
export PWD_KEY="pwd.key"
export CMAN_CONTAINER_NAME=racnodepc1-cman
export CMAN_IMAGE_NAME="oracle/client-cman:21.3.0"
export DNS_DOMAIN="example.com"
export CMAN_PUBLIC_IP=172.16.1.166
export CMAN_HOSTNAME="racnodepc1-cman"
export CMAN_PUBLIC_NETWORK_NAME="rac_pub1_nw"
export CMAN_PUBLIC_HOSTNAME="racnodepc1-cman"
export CMAN_VERSION="21.3.0"


export RACNODE2_CONTAINER_NAME=racnodep2
export RACNODE2_HOST_NAME=racnodep2
export RACNODE_IMAGE_NAME="localhost/oracle/database-rac:21.3.0-21.13.0"
export RACNODE2_NODE_VIP=172.16.1.201
export RACNODE2_VIP_HOSTNAME="racnodep2-vip"
export RACNODE2_PRIV_IP=192.168.17.171
export RACNODE2_PRIV_HOSTNAME="racnodep2-priv"
export RACNODE2_PUBLIC_IP=172.16.1.171
export RACNODE2_PUBLIC_HOSTNAME="racnodep2"


journalctl -b -u rc-local.service





Aug 28 17:33:29 racnodep1 systemd[1]: Starting /etc/rc.d/rc.local Compatibility...
Aug 28 17:33:29 racnodep1 systemd[1]: Started /etc/rc.d/rc.local Compatibility.
Aug 28 17:33:29 racnodep1 rc.local[106]: cat: /sys/fs/cgroup/memory/memory.limit_in_bytes: No such file or directory
Aug 28 17:33:29 racnodep1 rc.local[108]: cat: /sys/fs/cgroup/memory/memory.limit_in_bytes: No such file or directory
Aug 28 17:33:29 racnodep1 rc.local[87]: /opt/scripts/startup/runOracle.sh: line 55: [: -lt: unary operator expected
Aug 28 17:33:29 racnodep1 su[139]: (to grid) root on none
Aug 28 17:33:29 racnodep1 su[139]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:33:29 racnodep1 su[139]: pam_unix(su-l:session): session closed for user grid
Aug 28 17:33:29 racnodep1 rc.local[173]: Error: Nexthop has invalid gateway.
Aug 28 17:33:29 racnodep1 rc.local[176]: chown: changing ownership of '/common_scripts/..2024_08_28_17_33_27.1239146871/grid.rsp': Read-only file system
Aug 28 17:33:29 racnodep1 rc.local[176]: chown: changing ownership of '/common_scripts/..2024_08_28_17_33_27.1239146871': Read-only file system
Aug 28 17:33:29 racnodep1 rc.local[176]: chown: changing ownership of '/common_scripts/..data': Read-only file system
Aug 28 17:33:29 racnodep1 rc.local[176]: chown: changing ownership of '/common_scripts/grid.rsp': Read-only file system
Aug 28 17:33:29 racnodep1 rc.local[176]: chown: changing ownership of '/common_scripts': Read-only file system
Aug 28 17:33:29 racnodep1 rc.local[177]: chmod: changing permissions of '/common_scripts': Read-only file system
Aug 28 17:34:30 racnodep1 su[324]: (to grid) root on none
Aug 28 17:34:30 racnodep1 su[324]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:34:30 racnodep1 su[324]: pam_unix(su-l:session): session closed for user grid
Aug 28 17:35:00 racnodep1 rc.local[126]: 0
Aug 28 17:35:15 racnodep1 rc.local[530]: 3: eth1@if924: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc noqueue state UP mode DEFAULT group default
Aug 28 17:35:15 racnodep1 rc.local[550]: 4: eth2@if925: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc noqueue state UP mode DEFAULT group default
Aug 28 17:35:15 racnodep1 passwd[571]: pam_unix(passwd:chauthtok): password changed for grid
Aug 28 17:35:15 racnodep1 rc.local[571]: Changing password for user grid.
Aug 28 17:35:15 racnodep1 rc.local[571]: passwd: all authentication tokens updated successfully.
Aug 28 17:35:15 racnodep1 passwd[576]: pam_unix(passwd:chauthtok): password changed for oracle
Aug 28 17:35:15 racnodep1 rc.local[576]: Changing password for user oracle.
Aug 28 17:35:15 racnodep1 rc.local[576]: passwd: all authentication tokens updated successfully.
Aug 28 17:35:15 racnodep1 su[586]: (to grid) root on none
Aug 28 17:35:15 racnodep1 su[586]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:35:51 racnodep1 su[1103]: (to oracle) root on none
Aug 28 17:35:51 racnodep1 su[1103]: pam_unix(su-l:session): session opened for user oracle by (uid=0)
Aug 28 17:35:57 racnodep1 rc.local[410]: su - $GRID_USER -c "ssh -o BatchMode=yes -o ConnectTimeout=5 $GRID_USER@$node echo ok 2>&1"
Aug 28 17:35:57 racnodep1 su[1601]: (to grid) root on none
Aug 28 17:35:57 racnodep1 su[1601]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:35:57 racnodep1 su[1601]: pam_unix(su-l:session): session closed for user grid
Aug 28 17:35:57 racnodep1 rc.local[410]: su - $DB_USER -c "ssh -o BatchMode=yes -o ConnectTimeout=5 $DB_USER@$node echo ok 2>&1"
Aug 28 17:35:57 racnodep1 su[1659]: (to oracle) root on none
Aug 28 17:35:57 racnodep1 su[1659]: pam_unix(su-l:session): session opened for user oracle by (uid=0)
Aug 28 17:35:58 racnodep1 su[1659]: pam_unix(su-l:session): session closed for user oracle
Aug 28 17:35:58 racnodep1 su[1772]: (to grid) root on none
Aug 28 17:35:58 racnodep1 su[1772]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:35:58 racnodep1 su[1772]: pam_unix(su-l:session): session closed for user grid
Aug 28 17:35:58 racnodep1 su[1818]: (to grid) root on none
Aug 28 17:35:58 racnodep1 su[1818]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:35:58 racnodep1 su[1818]: pam_unix(su-l:session): session closed for user grid
Aug 28 17:35:58 racnodep1 su[1867]: (to grid) root on none
Aug 28 17:35:58 racnodep1 su[1867]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:35:58 racnodep1 rc.local[1889]: -bash: /etc/rac_env_vars: Permission denied
Aug 28 17:35:58 racnodep1 su[1867]: pam_unix(su-l:session): session closed for user grid
Aug 28 17:35:58 racnodep1 su[1896]: (to grid) root on none
Aug 28 17:35:58 racnodep1 su[1896]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:35:58 racnodep1 su[1896]: pam_unix(su-l:session): session closed for user grid
Aug 28 17:35:58 racnodep1 su[1942]: (to grid) root on none
Aug 28 17:35:58 racnodep1 su[1942]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:35:59 racnodep1 su[1942]: pam_unix(su-l:session): session closed for user grid
Aug 28 17:35:59 racnodep1 su[1991]: (to grid) root on none
Aug 28 17:35:59 racnodep1 su[1991]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:35:59 racnodep1 rc.local[2013]: -bash: /etc/rac_env_vars: Permission denied
Aug 28 17:35:59 racnodep1 su[1991]: pam_unix(su-l:session): session closed for user grid
Aug 28 17:35:59 racnodep1 su[2080]: (to grid) root on none
Aug 28 17:35:59 racnodep1 su[2080]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:36:26 racnodep1 su[5271]: (to grid) root on none
Aug 28 17:36:26 racnodep1 su[5271]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:36:29 racnodep1 su[5487]: (to grid) root on none
Aug 28 17:36:29 racnodep1 su[5487]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:36:29 racnodep1 su[5487]: pam_unix(su-l:session): session closed for user grid
Aug 28 17:36:29 racnodep1 su[5530]: (to grid) root on none
Aug 28 17:36:29 racnodep1 su[5530]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:36:29 racnodep1 su[5530]: pam_unix(su-l:session): session closed for user grid
Aug 28 17:36:29 racnodep1 su[5650]: (to grid) root on none
Aug 28 17:36:29 racnodep1 su[5650]: pam_unix(su-l:session): session opened for user grid by (uid=0)
Aug 28 17:36:37 racnodep1 su[6401]: (to oracle) root on none
Aug 28 17:36:37 racnodep1 su[6401]: pam_unix(su-l:session): session opened for user oracle by (uid=0)
Aug 28 17:36:41 racnodep1 su[6566]: (to oracle) root on none
Aug 28 17:36:41 racnodep1 su[6566]: pam_unix(su-l:session): session opened for user oracle by (uid=0)
Aug 28 17:36:41 racnodep1 su[6566]: pam_unix(su-l:session): session closed for user oracl
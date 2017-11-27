# set -e


#echo running systemd
#/usr/lib/systemd/systemd --system --unit=multi-user.target &

#sleep 5

# echo configuring priv and scan
# cat /etc/sysconfig/network-scripts/ifcfg-eth0-priv << EOF
# DEVICE=eth0-priv
# ONPARENT=yes
# IPADDR=172.31.33.1
# NETMASK=255.255.255.0

echo starting sshd
/usr/sbin/sshd
sudo -i -E -u grid ssh $POD_NAME date
sudo -i -E -u grid ssh $POD_IP date
sudo -i -E -u grid ssh oracle-rac-0.oracle-rac.oracle-rac.svc.cluster.local date

echo
echo running grid config

sudo -i -E -u grid $GRID_HOME/crs/config/config.sh -waitforcompletion \
-ignoreSysPrereqs -ignoreprereq -silent \
"INVENTORY_LOCATION=$ORACLE_INVENTORY_DIR" \
"oracle.install.option=CRS_CONFIG" \
"ORACLE_BASE=$GRID_BASE" \
"ORACLE_HOME=$GRID_HOME" \
"oracle.install.asm.OSDBA=asmdba" \
"oracle.install.asm.OSOPER=asmoper" \
"oracle.install.asm.OSASM=asmadmin" \
"oracle.install.crs.config.gpnp.scanName=scan-forwarder-0.scan-forwarder.oracle-rac.svc.cluster.local" \
"oracle.install.crs.config.gpnp.scanPort=1521 " \
"oracle.install.crs.config.ClusterType=STANDARD" \
"oracle.install.crs.config.clusterName=oracle-rac" \
"oracle.install.crs.config.gpnp.configureGNS=false" \
"oracle.install.crs.config.autoConfigureClusterNodeVIP=false" \
"oracle.install.crs.config.gpnp.gnsOption=CREATE_NEW_GNS" \
"oracle.install.crs.config.gpnp.gnsSubDomain=oracle-rac.svc.cluster.local" \
"oracle.install.crs.config.gpnp.gnsVIPAddress=oracle-rac-svc.oracle-rac.svc.cluster.local" \
"oracle.install.crs.config.clusterNodes=oracle-rac-0.oracle-rac.oracle-rac.svc.cluster.local:AUTO" \
"oracle.install.crs.config.networkInterfaceList=eth0:$POD_IP:1,eth0:$POD_IP:2" \
"oracle.install.crs.config.storageOption=LOCAL_ASM_STORAGE" \
"oracle.install.crs.config.useIPMI=false" \
"oracle.install.asm.SYSASMPassword=oracle_4U" \
"oracle.install.asm.monitorPassword=oracle_4U" \
"oracle.install.asm.diskGroup.name=DATA" \
"oracle.install.asm.diskGroup.redundancy=EXTERNAL" \
"oracle.install.asm.diskGroup.disks=/dev/asmdisks/asm-clu-121-DATA-disk1,/dev/asmdisks/asm-clu-121-DATA-disk2,/dev/asmdisks/asm-clu-121-DATA-disk3" \
"oracle.install.asm.diskGroup.diskDiscoveryString=/dev/asmdisks/*,/oraclenfs/asm*" \
"oracle.install.asm.useExistingDiskGroup=false"

echo
echo running root.sh
sh $GRID_HOME/root.sh

echo
echo running configToAllCommands
sudo -E -u grid $GRID_HOME/cfgtoollogs/configToolAllCommands \
RESPONSE_FILE=$GRID_BASE/tools_config.rsp

echo
echo running oracle config
sudo -E -u oracle $ORACLE_BASE/$RUN_FILE

wait
while true; do
  sleep 2
done
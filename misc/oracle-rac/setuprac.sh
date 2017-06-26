set -e

/usr/lib/systemd/systemd --system --unit=multi-user.target

sudo -E -u grid ' \
/u01/app/12.1.0/grid/crs/config/config.sh -waitforcompletion \
-ignoreSysPrereqs -ignoreprereq -silent \
"INVENTORY_LOCATION=$ORACLE_INVENTORY_DIR" \
"oracle.install.option=CRS_CONFIG" \
"ORACLE_BASE=$GRID_BASE" \
"ORACLE_HOME=$GRID_HOME" \
"oracle.install.asm.OSDBA=asmdba" \
"oracle.install.asm.OSOPER=asmoper" \
"oracle.install.asm.OSASM=asmadmin" \
"oracle.install.crs.config.gpnp.scanName=clu-121-scan.clu-121.example.com" \
"oracle.install.crs.config.gpnp.scanPort=1521 " \
"oracle.install.crs.config.ClusterType=STANDARD" \
"oracle.install.crs.config.clusterName=clu-121" \
"oracle.install.crs.config.gpnp.configureGNS=true" \
"oracle.install.crs.config.autoConfigureClusterNodeVIP=true" \
"oracle.install.crs.config.gpnp.gnsOption=CREATE_NEW_GNS" \
"oracle.install.crs.config.gpnp.gnsSubDomain=clu-121.example.com" \
"oracle.install.crs.config.gpnp.gnsVIPAddress=clu-121-gns.example.com" \
"oracle.install.crs.config.clusterNodes=rac1:AUTO" \
"oracle.install.crs.config.networkInterfaceList=eth-pub:10.10.10.0:1,eth-priv:11.11.11.0:2" \
"oracle.install.crs.config.storageOption=LOCAL_ASM_STORAGE" \
"oracle.install.crs.config.useIPMI=false" \
"oracle.install.asm.SYSASMPassword=oracle_4U" \
"oracle.install.asm.monitorPassword=oracle_4U" \
"oracle.install.asm.diskGroup.name=DATA" \
"oracle.install.asm.diskGroup.redundancy=EXTERNAL" \
"oracle.install.asm.diskGroup.disks=/dev/asmdisks/asm-clu-121-DATA-disk1,/dev/asmdisks/asm-clu-121-DATA-disk2,/dev/asmdisks/asm-clu-121-DATA-disk3" \
"oracle.install.asm.diskGroup.diskDiscoveryString=/dev/asmdisks/*,/oraclenfs/asm*" \
"oracle.install.asm.useExistingDiskGroup=false"'

sh $GRID_HOME/root.sh

sudo -E -u grid $GRID_HOME/cfgtoollogs/configToolAllCommands \
RESPONSE_FILE=$GRID_BASE/tools_config.rsp

sudo -E -u oracle $ORACLE_BASE/$RUN_FILE

wait

# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
#
# ORACLE DOCKERFILES PROJECT
# --------------------------
# This is the Dockerfile for Oracle Database 12c Release 1 Enterprise Edition
# 
# REQUIRED FILES TO BUILD THIS IMAGE
# ----------------------------------
# (1) linuxamd64_12102_database_1of2.zip
#     linuxamd64_12102_database_2of2.zip
#     Download Oracle Database 12c Release 1 Enterprise Edition for Linux x64
#     from http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html
#
# HOW TO BUILD THIS IMAGE
# -----------------------
# Put all downloaded files in the same directory as this Dockerfile
# Run: 
#      $ docker build -t oracle/database:12.1.0.2-ee . 
#
# Pull base image
# ---------------

FROM oraclelinux:7-slim
# Maintainer
# ----------
MAINTAINER Gerald Venzl <gerald.venzl@oracle.com>



# Environment variables required for this build (do NOT change)
# -------------------------------------------------------------
ENV GRID_BASE=/opt/grid \
    GRID_HOME=/opt/grid/product/12.1.0.2/grid \
    ORACLE_INVENTORY_DIR=/opt/oraInventory \
    ORACLE_BASE=/opt/oracle \
    ORACLE_HOME=/opt/oracle/product/12.1.0.2/dbhome_1 \
    INSTALL_RSP="db_inst.rsp" \
    CONFIG_RSP="dbca.rsp.tmpl" \
    PWD_FILE="setPassword.sh" \
    PERL_INSTALL_FILE="installPerl.sh" \
    RUN_FILE="runOracle.sh" \
    START_FILE="startDB.sh" \
    CREATE_DB_FILE="createDB.sh" \
    SETUP_LINUX_FILE="setupLinuxEnv.sh" \
    CHECK_SPACE_FILE="checkSpace.sh" \
    INSTALL_DB_BINARIES_FILE="installDBBinaries.sh" \
    INSTALL_DIR_BINARIES=/stage/12.1.0.2

# Use second ENV so that variable get substituted
ENV INSTALL_DIR=$ORACLE_BASE/install \
    PATH=$ORACLE_HOME/bin:$ORACLE_HOME/OPatch/:/usr/sbin:$PATH \
    LD_LIBRARY_PATH=$ORACLE_HOME/lib:/usr/lib \
    CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib   
    
VOLUME ["$INSTALL_DIR_BINARIES"]

# Copy binaries
# -------------
COPY $INSTALL_RSP $PERL_INSTALL_FILE $SETUP_LINUX_FILE $CHECK_SPACE_FILE $INSTALL_DB_BINARIES_FILE $INSTALL_DIR/
COPY $RUN_FILE $START_FILE $CREATE_DB_FILE $CONFIG_RSP $PWD_FILE $ORACLE_BASE/

RUN yum install -y sudo unzip perl && \
    chmod ug+x $INSTALL_DIR/*.sh && \
    sync && \
    $INSTALL_DIR/$CHECK_SPACE_FILE && \
    $INSTALL_DIR/$SETUP_LINUX_FILE && \
    yum update -y && \
    yum clean all && \
    
# add groups for grid    
    
    groupadd --force --gid 54321 oinstall && \
    groupmod --gid 54321 oinstall && \
    groupadd --gid 54421 asmdba && \
    groupadd --gid 54422 asmadmin && \
    groupadd --gid 54423 asmoper && \

# Add groups for database

    groupadd --force --gid 54322 dba && \
    groupmod --gid 54322 dba && \
    groupadd --gid 54323 oper && \
    groupadd --gid 54324 backupdba && \
    groupadd --gid 54325 dgdba && \
    groupadd --gid 54326 kmdba && \
    groupadd --gid 54327 racdba && \


# Add grid infrastructure owner    
    useradd --create-home --uid 54421 --gid oinstall --groups dba,asmdba,asmadmin,asmoper grid || \
      (RES=$? && ( [ $RES -eq 9 ] && exit 0 || exit $RES)) && \
    usermod --uid 54421 --gid oinstall --groups dba,asmdba,asmadmin,asmoper grid && \

# Add database owner
    useradd --create-home --uid 54321 --gid oinstall --groups dba,asmdba,oper,backupdba,dgdba,kmdba,racdba oracle || \
      (RES=$? && ( [ $RES -eq 9 ] && exit 0 || exit $RES)) && \
    usermod --uid 54321 --gid oinstall --groups dba,asmdba,oper,backupdba,dgdba,kmdba,racdba oracle  && \
 
# prepare dirs
    mkdir -p $GRID_BASE && \
    chgrp -R oinstall $GRID_BASE && \
    chmod -R 0775 $GRID_BASE && \
    mkdir -p $ORACLE_BASE && \
    chgrp -R oinstall $ORACLE_BASE && \
    chmod -R 0775 $ORACLE_BASE && \
    mkdir -p $ORACLE_INVENTORY_DIR && \
    chown -R grid:oinstall $ORACLE_INVENTORY_DIR && \
    chmod -R 0775 $ORACLE_INVENTORY_DIR        

#install grid  
#USER grid
RUN curl "http://$DOWNLOAD_URL/linuxamd64_12102_grid_1of2.zip" -o $INSTALL_DIR_BINARIES/linuxamd64_12102_grid_1of2.zip && \
    curl "http://$DOWNLOAD_URL/linuxamd64_12102_grid_2of2.zip" -o $INSTALL_DIR_BINARIES/linuxamd64_12102_grid_2of2.zip && \
    unzip $INSTALL_DIR_BINARIES/linuxamd64_12102_grid_1of2.zip -d $INSTALL_DIR_BINARIES && \
    unzip $INSTALL_DIR_BINARIES/linuxamd64_12102_grid_2of2.zip -d $INSTALL_DIR_BINARIES && \ 
    sudo -E -u grid $INSTALL_DIR_BINARIES/grid/runInstaller -waitforcompletion \
    -ignoreSysPrereqs -ignoreprereq -silent -force \
    INVENTORY_LOCATION=$ORACLE_INVENTORY_DIR \
    UNIX_GROUP_NAME=oinstall \
    ORACLE_HOME=$GRID_HOME \
    ORACLE_BASE=$GRID_BASE \
    oracle.install.option=CRS_SWONLY \
    oracle.install.asm.OSDBA=asmdba \
    oracle.install.asm.OSOPER=asmoper \
    oracle.install.asm.OSASM=asmadmin

USER root  
RUN $ORACLE_INVENTORY_DIR/orainstRoot.sh && \
    $GRID_HOME/root.sh    

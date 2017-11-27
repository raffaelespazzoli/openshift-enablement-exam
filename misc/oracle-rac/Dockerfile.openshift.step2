
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

FROM docker-registry.default.svc.cluster.local:5000/oracle-rac/oracle-rac-base-1:latest  
    
VOLUME ["$INSTALL_DIR_BINARIES"]

# Copy binaries
# -------------
COPY sudoers /etc
RUN usermod -a -G wheel oracle

# install orcale software
USER oracle
RUN sudo chmod -R a+rwx /stage && \
    ls -la /stage && \
    curl "http://$DOWNLOAD_URL/linuxamd64_12102_database_1of2.zip" -o $INSTALL_DIR_BINARIES/linuxamd64_12102_database_1of2.zip && \
    curl "http://$DOWNLOAD_URL/linuxamd64_12102_database_2of2.zip" -o $INSTALL_DIR_BINARIES/linuxamd64_12102_database_2of2.zip && \
    unzip $INSTALL_DIR_BINARIES/linuxamd64_12102_database_1of2.zip  -d $INSTALL_DIR_BINARIES && \
    unzip $INSTALL_DIR_BINARIES/linuxamd64_12102_database_2of2.zip -d $INSTALL_DIR_BINARIES && \   
    $INSTALL_DIR/$INSTALL_DB_BINARIES_FILE EE

USER root
RUN $ORACLE_INVENTORY_DIR/orainstRoot.sh && \
    $ORACLE_HOME/root.sh

USER oracle

RUN make -f $ORACLE_HOME/rdbms/lib/ins_rdbms.mk rac_on && \
    make -f $ORACLE_HOME/rdbms/lib/ins_rdbms.mk ioracle

WORKDIR /home/oracle

VOLUME ["$ORACLE_BASE/oradata"]

EXPOSE 1521 5500
    
# Define default command to start Oracle Database. 
CMD $ORACLE_BASE/$RUN_FILE

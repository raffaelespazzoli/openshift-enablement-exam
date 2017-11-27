
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

FROM docker-registry.default.svc.cluster.local:5000/oracle-rac/oracle-rac-base-2:latest  


RUN make -f $ORACLE_HOME/rdbms/lib/ins_rdbms.mk rac_on && \
    make -f $ORACLE_HOME/rdbms/lib/ins_rdbms.mk ioracle

USER root
RUN yum install -y openssh-server && \
    yum clean all && \
    mkdir -p /var/run/sshd && \
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
    
# Copy binaries
# -------------
COPY setuprac.sh $INSTALL_DIR/
COPY sshd_config ssh_config /etc/ssh/
RUN chmod +x $INSTALL_DIR/setuprac.sh

EXPOSE 22
    
# Define default command to start Oracle Database. 
CMD $INSTALL_DIR/setuprac.sh

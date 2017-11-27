#!/bin/bash
# LICENSE CDDL 1.0 + GPL 2.0
#
# Copyright (c) 1982-2017 Oracle and/or its affiliates. All rights reserved.
#
# Since: January, 2017
# Author: gerald.venzl@oracle.com
# Description: Checks the available space of the system.
# 
# DO NOT ALTER OR REMOVE COPYRIGHT NOTICES OR THIS HEADER.
# 

REQUIRED_SPACE_GB=12
df -B 1G .
echo available_space: `df -B 1G . | tail -n 1 | awk '{print $4'}`
if [ `df -B 1G . | tail -n 1 | awk '{print $4'}` -lt $REQUIRED_SPACE_GB ]; then
  script_name=`basename "$0"`
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  echo "$script_name: ERROR - There is not enough space available in the docker container."
  echo "$script_name: The container needs at least $REQUIRED_SPACE_GB GB available."
  echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
  exit 1;
fi;

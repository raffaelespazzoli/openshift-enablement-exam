#!/bin/bash

set -e
oc adm drain master1.c.openshift-enablement-exam2.internal --ignore-daemonsets
oc adm drain master2.c.openshift-enablement-exam2.internal --ignore-daemonsets
oc adm drain master3.c.openshift-enablement-exam2.internal --ignore-daemonsets

oc label node infranode1.c.openshift-enablement-exam2.internal region=infra zone=default --overwrite
oc label node infranode2.c.openshift-enablement-exam2.internal region=infra zone=default --overwrite 

node1.c.openshift-enablement-exam2.internal region=primary zone=default --overwrite
node2.c.openshift-enablement-exam2.internal region=primary zone=default --overwrite
node3.c.openshift-enablement-exam2.internal region=primary zone=default --overwrite
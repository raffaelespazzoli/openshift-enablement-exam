#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

RHOCP_VERSION=$(awk -F'"' '/VERSION_ID/{print $2}' /etc/os-release)
KERNEL_VERSION=$(uname -r)
KERNEL_CORE=$(find /tmp/overlay -name kernel-core-${KERNEL_VERSION}.rpm -exec ls {} \; | tail -n1)
KERNEL_DEVEL=$(find /tmp/overlay -name kernel-devel-${KERNEL_VERSION}.rpm -exec ls {} \; | tail -n1)
KERNEL_HEADERS=$(find /tmp/overlay -name kernel-headers-${KERNEL_VERSION}.rpm -exec ls {} \; | tail -n1)

if [ -z "${KERNEL_CORE}" ] || [ -z "${KERNEL_DEVEL}" ] || [ -z "${KERNEL_HEADERS}" ]; then
  KERNEL_CORE=kernel-core-${KERNEL_VERSION}
  KERNEL_DEVEL=kernel-devel-${KERNEL_VERSION}
  KERNEL_HEADERS=kernel-headers-${KERNEL_VERSION}
fi

dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
#dnf install -y --enablerepo=rhocp-${RHOCP_VERSION}-for-rhel-8-x86_64-rpms ${KERNEL_DEVEL} ${KERNEL_HEADERS} ${KERNEL_CORE}
dnf install -y ${KERNEL_DEVEL} ${KERNEL_HEADERS} ${KERNEL_CORE}
dnf install -y kmod-wireguard wireguard-tools iproute
dnf clean packages

modprobe wireguard

ip link add dev wg0-test type wireguard
ip link delete dev wg0-test

sleep infinity
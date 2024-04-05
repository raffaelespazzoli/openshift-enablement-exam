# KCP Helm Chart

This Helm chart deploys KCP, including the following components:

* KCP pod, including virtual workspace container
* Etcd
* Front proxy

## Dependencies

* cert-manager
* Openshift route

## Options

Currently configurable options:

* Etcd image and tag
* Etcd memory/cpu limit
* Etcd volume size
* KCP image and tag
* KCP memory/cpu limit
* KCP logging verbosity
* Virtual workspace memory/cpu limit
* Virtual workspace logging verbosity
* Audit logging
* OIDC
* Github user access to project
* External hostname

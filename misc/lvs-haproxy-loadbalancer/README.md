# HA Load Balancer for OpenShift

This playbook will create two HA load balancers, one for the masters and one for the default routers running on the infranodes 

As such this playbook should be run using and expanding an openshift-ansible inventory file.

This playbook should be run before OpenShift is deployed, so that the load balancers are available at deploy time.

Most of the information is deducted from the OpenShift inventory file.

Currently this playbook assumes that both the internal master FQDN and the external master FQDN resolve to the same VIP.  

The VIPs will be retrived by resolving the following FQDNs:

- master VIP: `{{ openshift_master_cluster_public_hostname }}`
- infranode VIP: `a.{{ openshift_master_default_subdomain }}`

If the DNS entries for the VIPs are not yet created, the VIPs can be specified as follow (replace with valid values for your environment):
```
master-VIP: '192.168.1.1'
infranode-VIP: '192.168.1.2'
```

This playbook expects two host groups:
```
[master-lbs]

[infranode-lbs]
```
Currently the playbook supports creating two separate load balancers, therefore these two groups must not have hosts in common. 

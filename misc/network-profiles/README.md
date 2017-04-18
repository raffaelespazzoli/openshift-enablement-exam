# Network Policies

You need to install the cluster with this option: `os_sdn_network_plugin_name='redhat/openshift-ovs-networkpolicy'`


# Setting up a the project default
By default any project can communicate with any project.

excract the project template
```
oadm create-bootstrap-project-template -o yaml > template.yaml
```

If you want deny all as your default
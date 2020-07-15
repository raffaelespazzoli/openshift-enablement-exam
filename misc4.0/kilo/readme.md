# Installation 

This assumes you have deployed three clusters as per the [acm instructions](./../acm/readme.md).

## Deploy wireguard kernel driver

```shell
oc new-project kilo
oc adm policy add-scc-to-user privileged -z default -n kilo
oc apply -f ./wireguard-module-install.yaml -n kilo
```
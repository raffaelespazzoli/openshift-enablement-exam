# how to compile/inject wireguard kernel modules in RHCOS

## Disable pod automount

```shell
oc apply -f ./disable_automount_machineset.yaml
```

## Create entitlement secret

download you entitlement as explained [here] (https://www.openshift.com/blog/how-to-use-entitled-image-builds-to-build-drivercontainers-with-ubi-on-openshift) and put them in `./entitlements`.
There should be two files in that dir.

```shell
oc new-project wireguard
export id=$(ls ./entitlements | head -n 1 | sed "s/\..*//")
oc create secret generic entitlement --from-file=entitlement.pem=./entitlements/${id}.pem --from-file=entitlement-key.pem=./entitlements/${id}.pem -n wireguard
oc create configmap module-injection --from-file=./module-injection.sh -n wireguard
oc adm policy add-scc-to-user privileged -z default -n wireguard
oc apply -f ./wireguard-ds.yaml
```

## Create the wireguard daemonset




https://www.openshift.com/blog/how-to-use-entitled-image-builds-to-build-drivercontainers-with-ubi-on-openshift
https://github.com/sjug/wg-rhcos
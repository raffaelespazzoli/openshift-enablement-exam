# how to compile/inject wireguard kernel modules in RHCOS

## First approach, node entitlement (preferred)

## Entitle the nodes

Procure an entitlement, this can usually be done in the customer portals: Systems->Subscriptions->Download.
Extract the archive and move the file in `export/entitlement_certificates/*.pem` to the `./entitlements` folder.
Also explained [here] (https://www.openshift.com/blog/how-to-use-entitled-image-builds-to-build-drivercontainers-with-ubi-on-openshift).

```shell
export entitlement_file=./entitlements/5823737155490860066.pem
base64 -w0 ${entitlement_file} > /tmp/base64_entitlement
sed  "s/BASE64_ENCODED_PEM_FILE/$(cat /tmp/base64_entitlement)/g" entitlement.yaml | oc apply -f -
#note: for some reasons these commands don't work in my shell so I had to run them manually
```

### Deploy wireguard modules

```shell
oc new-project wireguard
oc delete configmap module-injection -n wireguard
oc create configmap module-injection --from-file=./module-injection.sh -n wireguard
oc adm policy add-scc-to-user privileged -z default -n wireguard
oc apply -f ./wireguard-ds-node.yaml -n wireguard
```

## Second approach, pod entitlement

### Remove entitlement mount

```shell
oc apply -f ./disable_automount_machineset.yaml
```

### Deploy wireguard

download you entitlement as explained [here] (https://www.openshift.com/blog/how-to-use-entitled-image-builds-to-build-drivercontainers-with-ubi-on-openshift) and put them in `./entitlements`.

```shell
oc new-project wireguard
export id=$(ls ./entitlements | head -n 1 | sed "s/\..*//")
oc create secret generic entitlement --from-file=entitlement.pem=./entitlements/${id}.pem --from-file=entitlement-key.pem=./entitlements/${id}.pem -n wireguard
oc create configmap module-injection --from-file=./module-injection.sh -n wireguard
oc adm policy add-scc-to-user privileged -z default -n wireguard
oc apply -f ./wireguard-ds.yaml -n wireguard
```



https://www.openshift.com/blog/how-to-use-entitled-image-builds-to-build-drivercontainers-with-ubi-on-openshift
https://github.com/sjug/wg-rhcos
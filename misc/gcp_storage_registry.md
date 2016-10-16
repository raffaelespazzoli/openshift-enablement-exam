The registry pods start with an NFS volume for storage.
run this to use a google storage:

```
oc scale dc docker-registry --replicas=0 -n default
oc secrets new registry-config config.yml=registry.config.yml -n default
oc volume dc/docker-registry --remove --name=registry-storage
oc volume dc/docker-registry --add --type=secret --secret-name=registry-config -m /etc/docker/registry/ -n default
oc env dc/docker-registry REGISTRY_CONFIGURATION_PATH=/etc/docker/registry/config.yml -n default
oc deploy docker-registry --latest -n default
oc scale dc docker-registry --replicas=2 -n default
```
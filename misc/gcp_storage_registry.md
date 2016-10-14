The registry pods start with an NFS volume for storage.
run this to use a google storage:

```
oc secrets new registry-config config.yml=</path/to/custom/registry/config.yml>
oc volume dc/docker-registry --add --type=secret --secret-name=registry-config -m /etc/docker/registry/
oc env dc/docker-registry REGISTRY_CONFIGURATION_PATH=/etc/docker/registry/config.yml
```
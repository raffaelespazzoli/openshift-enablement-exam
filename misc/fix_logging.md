logging comes up with an empty dir volume type as storage even though a dynamic pvc was requested in the installer. to fix this run:
```
oc create -f logging_dpvc.yaml -n logging
oc scale rc `oc get rc | grep logging-es | awk '{print $1}'` --replicas=0
oc volume rc/`oc get rc | grep logging-es | awk '{print $1}'` --add -m /elasticsearch/persistent --claim-name=logging-kibana --overwrite=true -n logging
oc scale rc `oc get rc | grep logging-es | awk '{print $1}'` --replicas=1
```
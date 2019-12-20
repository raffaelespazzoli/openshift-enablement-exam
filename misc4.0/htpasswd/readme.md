
```shell
htpasswd -c -B -b htpasswd raffa raffa
oc create secret generic htpass-secret --from-file=htpasswd=htpasswd -n openshift-config
oc apply -f oauth.yaml -n openshift-config
```

#egress test

create a project
```
oc new-project egress-test
```
create the test app
```
oc new-app https://github.com/raffaelespazzoli/openshift-enablement-exam --context-dir=misc/egress --strategy=docker --name=app=egress-test -labels=egress-test -n egress-test
```

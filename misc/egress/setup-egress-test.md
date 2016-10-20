#egress test

create a project
```
oc new-project egress-test
```
create the test app
```
oc new-app https://github.com/raffaelespazzoli/openshift-enablement-exam --context-di=misc/egress --strategy=docker --name=egress-test --l egress-test -n egress-test
```

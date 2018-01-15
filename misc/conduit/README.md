# conduit installation instructions

install binary
```
curl https://run.conduit.io/install | sh
sudo cp $HOME/.conduit/bin/conduit /usr/bin
```
deploy conduit
```
oc new-project conduit
conduit install | oc apply -f -
oc set volume deployment/prometheus --add -m prometheus/data -t pvc --claim-size=1GB --claim-class=glusterfs-storage
```
view the console
```
conduit dashboard
```
deploy the example
```
oc new-project emojivoto
oc create -f anyuid-netadmin.yaml
oc adm policy add-scc-to-user anyuid-netadmin -z default
curl https://raw.githubusercontent.com/runconduit/conduit-examples/master/emojivoto/emojivoto.yml | conduit inject - --skip-inbound-ports=80 | oc apply -f -
```
# install the postegresql operator cli
```
curl -L -o /tmp/postgres-operator.2.4.tar.gz https://github.com/CrunchyData/postgres-operator/releases/download/2.4/postgres-operator.2.4.tar.gz
tar -zxvf /tmp/postgres-operator.2.4.tar.gz -C /tmp
sudo cp /tmp/pgo /usr/bin
```

# install the postgresql operator

```
export COROOT=$GOPATH/src/github.com/crunchydata/postgres-operator
export CO_BASEOS=centos7
export CO_VERSION=2.4
export CO_IMAGE_TAG=$CO_BASEOS-$CO_VERSION
export CO_NAMESPACE=pgo
export CO_CMD=oc
export CO_APISERVER_URL=https://postgres-operator:8443
export PGO_CA_CERT=$COROOT/conf/apiserver/server.crt
export PGO_CLIENT_CERT=$COROOT/conf/apiserver/server.crt
export PGO_CLIENT_KEY=$COROOT/conf/apiserver/server.key
```
```
cd $GOPATH/src/github.com/crunchydata
git clone https://github.com/CrunchyData/postgres-operator.git
cd postgres-operator
```

```
oc new-project pgo
oc adm policy add-cluster-role-to-user cluster-admin -z default
oc create -f ./crunchy/crunchy-pvc.yaml

oc create configmap apiserver-conf \
  --from-file=./crunchy/conf/apiserver/pgouser \
  --from-file=./crunchy/conf/apiserver/pgo.yaml \
  --from-file=./crunchy/conf/apiserver/pgo.load-template.json \
  --from-file=./crunchy/conf/apiserver/pgo.lspvc-template.json 
  
oc create configmap operator-conf \
  --from-file=./crunchy/conf/postgres-operator/backup-job.json \
  --from-file=./crunchy/conf/postgres-operator/rmdata-job.json \
  --from-file=./crunchy/conf/postgres-operator/pvc.json \
  --from-file=./crunchy/conf/postgres-operator/pvc-storageclass.json \
  --from-file=./crunchy/conf/postgres-operator/cluster/1  
  
oc process -f ./crunchy/crunchy-template.yaml | oc apply -f -
oc create route reencrypt --service=postgres-operator

export CO_NAMESPACE=pgo
export CO_APISERVER_URL=https://`oc get route | grep -m1 postgres-operator | awk '{print $2}'`
pod=`oc get pods | grep postgres-operator | awk '{print $1}'`
oc exec $pod -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt >> /tmp/ca.crt
oc exec $pod -- cat /config/server.crt >> /tmp/server.crt
oc exec $pod -- cat /config/server.key >> /tmp/server.key
export PGO_CA_CERT=/tmp/ca.crt
export PGO_CLIENT_CERT=/tmp/server.crt
export PGO_CLIENT_KEY=/tmp/server.key
```
  
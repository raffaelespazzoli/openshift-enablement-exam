## setting up HDFS

oc new-project hdfs
oc create configmap hadoopenv --from-file=./hadoop.env
oc adm policy add-scc-to-user anyuid -z default
oc apply -f hdfs.yaml
oc expose svc namenode --port=50070
oc expose svc resourcemanager --port=8088
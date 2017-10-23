oc new-project tensorflow
oc adm policy add-scc-to-user anyuid -z default
oc new-app tensorflow/tensorflow
oc expose svc tensorflow --port=8888
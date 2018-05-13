```
oc new-project selenium-grid
oc apply -f https://raw.githubusercontent.com/kubernetes/examples/master/staging/selenium/selenium-hub-deployment.yaml
oc apply -f https://raw.githubusercontent.com/kubernetes/examples/master/staging/selenium/selenium-hub-svc.yaml
oc apply -f https://raw.githubusercontent.com/kubernetes/examples/master/staging/selenium/selenium-node-chrome-deployment.yaml
oc apply -f https://raw.githubusercontent.com/kubernetes/examples/master/staging/selenium/selenium-node-firefox-deployment.yaml



```
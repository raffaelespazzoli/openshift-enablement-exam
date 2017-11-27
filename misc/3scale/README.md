oc new-project 3scale-onprem

oc process -f https://raw.githubusercontent.com/3scale/3scale-amp-openshift-templates/master/amp/pvc.yml | oc create -f -

oc process -f https://raw.githubusercontent.com/3scale/3scale-amp-openshift-templates/master/amp/amp.yml -p WILDCARD_DOMAIN=3scale-onprem.apps.gc1.raffa.systems | oc create -f -

oc process -f https://raw.githubusercontent.com/3scale/3scale-amp-openshift-templates/master/amp/pvc.yml -p WILDCARD_DOMAIN=3scale-onprem.apps.gc1.raffa.systems | oc create -f -
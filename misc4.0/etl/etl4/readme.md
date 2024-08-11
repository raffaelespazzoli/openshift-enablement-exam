# OpenShift AI Setup

The intent of this repo is to show how to setup OpenShift AI.

The idea is to have servicemesh and serverlss externalized from the OpenShift AI operator and managed externally. This is a more realistic setup for complex scenario.

The other distinction of this repo is the setup up of the entire observability stack.



## Getting started with this repo

run

```sh
export gitops_repo=https://github.com/raffaelespazzoli/openshift-enablement-exam.git #<your newly created repo>
export cluster_name=etl4 #<your hub cluster name, typically "hub">
export cluster_base_domain=$(oc get ingress.config.openshift.io cluster --template={{.spec.domain}} | sed -e "s/^apps.//")
export platform_base_domain=${cluster_base_domain#*.}
export infrastructure_id=$(oc get infrastructure cluster -o jsonpath='{.status.infrastructureName}')
oc apply -f misc4.0/etl/etl4/.bootstrap/subscription.yaml
oc apply -f misc4.0/etl/etl4/.bootstrap/cluster-rolebinding.yaml
sleep 60
envsubst < misc4.0/etl/etl4/.bootstrap/argocd.yaml | oc apply -f -
sleep 30
envsubst < misc4.0/etl/etl4/.bootstrap/root-application.yaml | oc apply -f -
```

If you are using RHDP, after a restart run this to deal with the annoying race condition affecting ArgoCD

```sh
oc rollout restart deployment/openshift-gitops-operator-controller-manager -n openshift-operators
oc delete pods --all -n openshift-gitops
```


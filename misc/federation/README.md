# add federation control plane

```
git clone https://github.com/kubernetes/kubernetes
cd kubernetes
export FEDERATION_OUTPUT_ROOT="${PWD}/_output/federation"
mkdir -p "${FEDERATION_OUTPUT_ROOT}"
#if necessary run this:
gcloud auth application-default login
federation/deploy/deploy.sh init
sudo set enforce 0
federation/deploy/deploy.sh deploy_federation
sudo set enforce 1
oc create sa federation
oc adm policy add-scc-to-user hostmount-anyuid -z federation
oc patch deployment/federation-apiserver --patch '{"spec":{"template":{"spec":{"serviceAccountName": "federation"}}}}'
oc patch deployment/federation-controller-manager --patch '{"spec":{"template":{"spec":{"serviceAccountName": "federation"}}}}'

```
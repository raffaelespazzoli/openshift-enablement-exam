# Installing sigstore on OCP

## Install cert-manager + let's encrypt for external-facing certs

```sh
helm upgrade -i \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.11.0 \
  --set installCRDs=true \
  --set "extraArgs={--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=8.8.8.8:53}" \
  --set global.leaderElection.namespace=cert-manager
export base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
export hosted_zone=$(oc get dns cluster -o jsonpath='{.spec.publicZone.id}')
export region=$(oc get infrastructure cluster -o jsonpath='{.status.platformStatus.aws.region}')
envsubst < ./cert-manager/credential-request.yaml | oc apply -f - 

# wait a few seconds

export access_key_id=$(oc get secret cert-manager-dns-credentials -n cert-manager -o jsonpath='{.data.aws_access_key_id}' | base64 -d )
envsubst < ./cert-manager/letsencrypt-issuer.yaml | oc apply -f -
envsubst < ./cert-manager/cluster-certificate.yaml | oc apply -f -

# wait a few seconds

export tls_key=$(oc get secret lets-encrypt-certs-tls -n openshift-ingress -o jsonpath='{.data.tls\.key}')
export tls_crt=$(oc get secret lets-encrypt-certs-tls -n openshift-ingress -o jsonpath='{.data.tls\.crt}')
oc patch secret lets-encrypt-certs-tls -n openshift-ingress -p '{"data":{"cert": "'"${tls_cert}"'", "key": "'"${tls_key}"'"}}'
oc patch IngressController default -n openshift-ingress-operator -p '{"spec": {"defaultCertificate": {"name": "lets-encrypt-certs-tls"}}}' --type merge
```

## Install rh-sso for human OIDC

```sh
oc new-project rh-sso
oc apply -f ./rh-sso/operator.yaml -n rh-sso
oc apply -f ./rh-sso/keycloak.yaml -n rh-sso
oc apply -f ./rh-sso/client.yaml -n rh-sso
oc apply -f ./rh-sso/realm.yaml -n rh-sso
oc apply -f ./rh-sso/user.yaml -n rh-sso
```

## Install spire for system OIDC

```sh
# Install security profile
oc create namespace openshift-security-profiles
oc apply -f ./security-profiles-operator/operator.yaml
oc patch spod spod -n openshift-security-profiles --type='json' -p='[{"op": "add", "path": "/spec/selinuxOptions/allowedSystemProfiles/-", "value":"net_container"}]'
oc apply -f ./security-profiles-operator/selinux-profile.yaml -n openshift-security-profiles

# install spiffe/spire
oc new-project spire-system
export base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
helm upgrade spire ./spire/chart/spire -i --create-namespace -n spire-system --set base_domain=${base_domain}
```

test spire

```sh
oc new-project test-spire
oc label namespace test-spire spiffe-enabled=true
oc adm policy add-scc-to-user restricted-csi -z default -n test-spire
oc apply -n test-spire -f ./spire/test-spire.yaml
# in the container run the following to test:
/opt/spire/bin/spire-agent api fetch -socketPath /spiffe-workload-api/agent.sock
```


## Install sigstore


```sh
oc new-project fulcio-system 
oc new-project rekor-system 
oc new-project ctlog-system 
oc new-project trillian-system
oc new-project tuf-system 
oc new-project sigstore 
oc adm policy add-scc-to-user nonroot-v2 -z fulcio-server -n fulcio-system
oc adm policy add-scc-to-user nonroot-v2 -z fulcio-createcerts -n fulcio-system
oc adm policy add-scc-to-user nonroot-v2 -z rekor-server -n rekor-system
oc adm policy add-scc-to-user nonroot-v2 -z scaffold-rekor-createtree -n rekor-system
oc adm policy add-scc-to-user nonroot-v2 -z ctlog-createtree -n ctlog-system
oc adm policy add-scc-to-user nonroot-v2 -z scaffold-ctlog-createctconfig -n ctlog-system
oc adm policy add-scc-to-user nonroot-v2 -z ctlog -n ctlog-system
oc adm policy add-scc-to-user anyuid -z tuf -n tuf-system

helm repo add sigstore https://sigstore.github.io/helm-charts
export base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
envsubst < ./sigstore/scaffold-values-tpl.yaml > /tmp/scaffold-values.yaml
helm upgrade -i scaffold sigstore/scaffold -n sigstore --values /tmp/scaffold-values.yaml
```


## Install Vault + transit KMS for sigstore

```sh
helm repo add hashicorp https://helm.releases.hashicorp.com
oc new-project vault
oc adm policy add-role-to-user admin -z vault -n vault
export base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
helm upgrade vault hashicorp/vault -i --create-namespace -n vault --atomic -f ./vault/vault-values.yaml --set server.route.host=vault-vault.apps.${base_domain}

#configure kube auth
export VAULT_ADDR=https://vault-vault.apps.${base_domain}
export VAULT_TOKEN=$(oc get secret vault-init -n vault -o jsonpath='{.data.root_token}' | base64 -d )
# this policy is intentionally broad to allow to test anything in Vault. In a real life scenario this policy would be scoped down.
vault policy write vault-admin  ./vault/vault-admin-policy.hcl
vault auth enable kubernetes
vault write auth/kubernetes/config kubernetes_host=https://kubernetes.default.svc:443
vault write auth/kubernetes/role/ci-system bound_service_account_names=pipeline bound_service_account_namespaces='*' policies=vault-admin ttl=10s

#configure transit
vault secrets enable transit
cosign generate-key-pair --kms hashivault://ci-system
```

## Install tekton and tekton chain configured to use cosign + OCI store for attestations

```sh
oc apply -f ./openshift-pipelines/operator.yaml
```

## Configure openshift pipelines

```sh
oc apply -f ./openshift-pipelines/tektonchain.yaml
oc patch configmap chains-config -n openshift-pipelines -p='{"data":{"artifacts.oci.storage": "oci"}}' 
oc patch configmap chains-config -n openshift-pipelines -p='{"data":{"artifacts.taskrun.format": "in-toto"}}'
oc patch configmap chains-config -n openshift-pipelines -p='{"data":{"artifacts.taskrun.storage": "oci"}}'
oc patch configmap chains-config -n openshift-pipelines -p='{"data":{"transparency.enabled": "false"}}'
oc patch configmap chains-config -n openshift-pipelines -p='{"data":{"artifacts.pipelinerun.format": "in-toto"}}'
oc patch configmap chains-config -n openshift-pipelines -p='{"data":{"artifacts.pipelinerun.storage": "oci"}}'
cosign generate-key-pair k8s://openshift-pipelines/signing-secrets
```

## Create a simple pipeline to test

This pipeline demonstrates the use of three signing approaches (one would never do this in a real environment)

- key-based signing, performed by the tekton chain controller
- KMS-based signing, performed during the SBOM task
- keyless signing, performed during the vulnerability scan task

create the pipeline

```sh
oc new-project test-sigstore
oc create secret docker-registry quay-push --docker-username=raffaelespazzoli --docker-password=<password> --docker-server=quay.io -n test-sigstore
oc patch serviceaccount pipeline -p "{\"imagePullSecrets\": [{\"name\": \"quay-push\"}]}" -n test-sigstore
oc patch secret quay-push -n test-sigstore -p "{\"data\": {\"config.json\": \"$(oc get secret quay-push -n test-sigstore -o jsonpath={.data."\.dockerconfigjson"})\"}}"
oc label namespace test-sigstore spiffe-enabled=true
oc adm policy add-scc-to-user restricted-csi -z pipeline -n test-sigstore
oc apply -f ./pipeline/syft-task.yaml 
oc apply -f ./pipeline/grype-task.yaml 
oc apply -f ./pipeline/pipeline-pvc.yaml -n test-sigstore
oc apply -f ./pipeline/pipeline-ci.yaml -n test-sigstore
```

run the pipeline

```sh
oc create -f ./pipeline/pipeline-ci-run.yaml -n test-sigstore
```


## Deploying sigstore admission controller

```sh
helm upgrade policy-controller sigstore/policy-controller -i --create-namespace -n cosign-system -f ./sigstore/policy-controller-values.yaml --devel
oc adm policy add-scc-to-user nonroot-v2 -z policy-controller-webhook -n cosign-system
oc create secret signing-secrets -n cosign-system
oc patch secret signing-secrets -n cosign-system -p '{"data": {"cosign.pub": "'"$(oc get secret signing-secrets -n openshift-pipelines -o jsonpath={.data."cosign\.pub"})"'"}}'
```


## Verifying policies

create policies

```sh
oc label namespace test-sigstore policy.sigstore.dev/include=true
oc apply -f ./policies/tekton-attestation.yaml
oc apply -f ./policies/sbom-attestation.yaml
oc apply -f ./policies/sarif-attestation.yaml
```

test policies:

```sh
oc apply -f ./policies/deployment.yaml -n test-sigstore
```


## Deploy kyverno admission controller

```sh
helm repo add kyverno https://kyverno.github.io/kyverno/
helm upgrade kyverno kyverno/kyverno -i -n kyverno --create-namespace --set replicaCount=3
```

Deploy kyverno policy

```sh
oc apply -f ./policies/kyverno-cluster-policy.yaml
```

```sh
oc new-project test-kyverno
oc apply -f ./policies/deployment.yaml -n test-kyverno
```


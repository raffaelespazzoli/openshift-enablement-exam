# Using custom certificate for OCP4 endpoints

This repository help you set up OCP 4 to use custom certificates (likely signed by the company's CA) for out-of-the-box routes.

We are going to use the [cert-manager](https://cert-manager.readthedocs.io/en/latest/) operator to provision certificates.
We are going to use [Let's Encrypt](https://letsencrypt.org/) as our external CA. In real customer scenario this would be something else, but outside of the configuration of the cluster issuer (see below), everything else stays the same.

## Installing cert manager

run the following:

```shell
oc new-project cert-manager
oc label namespace cert-manager certmanager.k8s.io/disable-validation=true
oc apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v0.8.1/cert-manager-openshift.yaml
```

## Creating the let's encrypt cluster issuer

This steps may change depending on the CA product that your company wants to use.

```shell
export EMAIL=<your-lets-encrypt-email>
oc apply -f lets_encrypt_issuer/aws-credential.yaml
export AWS_ACCESS_KEY_ID=$(oc get secret cert-manager-dns-credentials -n cert-manager -o jsonpath='{.data.aws_access_key_id}' | base64 -d)
export REGION=$(oc get nodes --template='{{ with $i := index .items 0 }}{{ index $i.metadata.labels "failure-domain.beta.kubernetes.io/region" }}{{ end }}')
export zoneid=$(oc get dns cluster -o jsonpath='{.spec.publicZone.id}')
envsubst < lets_encrypt_issuer/lets-encrypt-issuer.yaml | oc apply -f - -n cert-manager
```

## Replacing all the out of the box Routes

the only way to do is to replace the default certificate of the default ingresscontroller

```shell
export basedomain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
namespace=openshift-ingress route=default host='*.apps.'${basedomain} envsubst < routes/wildcard-certificate.yaml | oc apply -f -
oc patch --type=merge --namespace openshift-ingress-operator ingresscontrollers/default --patch '{"spec":{"defaultCertificate":{"name":"cert-manager-default"}}}'
```

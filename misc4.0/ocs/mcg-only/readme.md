## Install ODF operator

```sh
oc adm new-project openshift-storage
oc label namespace openshift-storage openshift.io/cluster-monitoring="true"
oc apply -f ./operator/operator.yaml
```

## Install MCG

```sh
oc apply -f ./application/noobaa.yaml
oc apply -f ./application/backing-store.yaml
...
oc patch bucketclass noobaa-default-bucket-class --patch '{"spec":{"placementPolicy":{"tiers":[{"backingStores":["noobaa-pv-backing-store"]}]}}}' --type merge -n openshift-storage
```

## Configure internal registry

```sh
oc apply -f ./configuration/object-bucket-claim.yaml

bucket_name=$(oc get obc -n openshift-storage registry -o jsonpath='{.spec.bucketName}')
AWS_ACCESS_KEY_ID=$(oc get secret -n openshift-storage registry -o yaml | grep -w "AWS_ACCESS_KEY_ID:" | head -n1 | awk '{print $2}' | base64 --decode)
AWS_SECRET_ACCESS_KEY=$(oc get secret -n openshift-storage registry -o yaml | grep -w "AWS_SECRET_ACCESS_KEY:" | head -n1 | awk '{print $2}' | base64 --decode)
oc create secret generic image-registry-private-configuration-user --from-literal=REGISTRY_STORAGE_S3_ACCESSKEY=${AWS_ACCESS_KEY_ID} --from-literal=REGISTRY_STORAGE_S3_SECRETKEY=${AWS_SECRET_ACCESS_KEY} --namespace openshift-image-registry
route_host=$(oc get route s3 -n openshift-storage -o=jsonpath='{.spec.host}')

oc patch config.image/cluster -p '{"spec":{"managementState":"Managed","replicas":2,"storage":{"managementState":"Unmanaged","s3":{"bucket":'\"${bucket_name}\"',"region":"us-east-1","regionEndpoint":'\"https://${route_host}\"',"virtualHostedStyle":false,"encrypt":false}}}}' --type=merge

## not needed if using a signed cert
oc extract secret/router-certs-default  -n openshift-ingress  --confirm
oc create configmap image-registry-s3-bundle --from-file=ca-bundle.crt=./tls.crt  -n openshift-config
oc patch config.image/cluster -p '{"spec":{"managementState":"Managed","replicas":2,"storage":{"managementState":"Unmanaged","s3":{"bucket":'\"${bucket_name}\"',"region":"us-east-1","regionEndpoint":'\"https://${route_host}\"',"virtualHostedStyle":false,"encrypt":false,"trustedCA":{"name":"image-registry-s3-bundle"}}}}}' --type=merge
## end not needed


```

refer also to:

https://access.redhat.com/documentation/en-us/red_hat_quay/3.8/html/deploy_red_hat_quay_on_openshift_with_the_quay_operator/operator-preconfigure#create_a_standalone_object_gateway

https://docs.openshift.com/container-platform/4.12/registry/configuring_registry_storage/configuring-registry-storage-rhodf.html#registry-configuring-registry-storage-rhodf-nooba_configuring-registry-storage-rhodf
#!/bin/bash

set -e
gcloud config set project $GCLOUD_PROJECT

project_number = `gcloud projects describe $GCLOUD_PROJECT | grep projectNumber | awk '{print $2}' | sed "s/^\([\"']\)\(.*\)\1\$/\2/g"`

! gcloud deployment-manager deployments delete openshift -q

gcloud deployment-manager deployments create openshift --config openshift-gcloud.yaml --properties=project_number=$project_number


gcloud compute instance-groups unmanaged add-instances master1 --instances master1 --zone us-central1-a &
gcloud compute instance-groups unmanaged add-instances master2 --instances master2 --zone us-central1-b &
gcloud compute instance-groups unmanaged add-instances master3 --instances master3 --zone us-central1-c &
wait

#create storage for registry
#gsutil mb -c Standard -l us-central1 -p $GCLOUD_PROJECT gs://$GCLOUD_PROJECT-registry

#create dns zone only if it already does not exists
if [ `gcloud dns managed-zones list | grep $DNS_DOMAIN | wc -l` -ne 1  ]; then
gcloud dns managed-zones create --dns-name="$DNS_DOMAIN" --description="A zone" "$GCLOUD_PROJECT"
fi

# add records to dns zone
gcloud dns record-sets transaction start -z="$GCLOUD_PROJECT"
gcloud dns record-sets transaction add -z="$GCLOUD_PROJECT" --name="master.$DNS_DOMAIN" --type=A --ttl=300 `gcloud compute addresses list | grep master-external | awk '{print $3}'`
gcloud dns record-sets transaction add -z="$GCLOUD_PROJECT" --name="*.apps.$DNS_DOMAIN" --type=A --ttl=300 `gcloud compute addresses list | grep infranode-external | awk '{print $3}'`
gcloud dns record-sets transaction add -z="$GCLOUD_PROJECT" --name="master-internal.$DNS_DOMAIN" --type=A --ttl=300 `gcloud compute forwarding-rules list master-internal | awk 'NR>1 {print $3}'`
gcloud dns record-sets transaction add -z="$GCLOUD_PROJECT" --name="mi.$DNS_DOMAIN" --type=A --ttl=300 `gcloud compute forwarding-rules list master-internal | awk 'NR>1 {print $3}'`
gcloud dns record-sets transaction execute -z="$GCLOUD_PROJECT"
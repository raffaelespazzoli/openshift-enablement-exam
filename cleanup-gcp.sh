#!/bin/bash

set -e
gcloud config set project $GCLOUD_PROJECT

#delete forwarding rules
for i in $(gcloud compute forwarding-rules list | awk 'NR>1 {print $1}'); do
	gcloud compute forwarding-rules delete -q $i --region "us-central1";
done

#delete target pools
for i in $(gcloud compute target-pools list | awk 'NR>1 {print $1}'); do
	gcloud compute target-pools delete -q $i --region "us-central1";
done

#delete static address
for i in $(gcloud compute addresses list | awk 'NR>1 {print $1}'); do
	gcloud compute addresses delete -q $i --region "us-central1";
done

#delete backend-services
for i in $(gcloud beta compute backend-services list | awk 'NR>1 {print $1}'); do
	gcloud beta compute backend-services delete -q $i --region "us-central1";
done

#delete health checks
for i in $(gcloud compute health-checks list | awk 'NR>1 {print $1}'); do
	gcloud compute health-checks delete -q $i --region "us-central1";
done

#delete instance-groups
for i in $(gcloud compute instance-groups list | awk 'NR>1 {print $1}'); do
	gcloud compute instance-groups delete -q $i --region "us-central1";
done

#delete VMs
for k in us-central1-a us-central1-b us-central1-c; do
 for i in $(gcloud compute instances list --zones $k| awk 'NR>1 {print $1}'); do
gcloud compute instances delete $i -q --zone "$k";
 done;
done	


#delete disks
for k in us-central1-a us-central1-b us-central1-c; do
 for i in $(gcloud compute disks list --zones $k | awk 'NR>1 {print $1}'); do
gcloud compute disks delete -q $i --zone $k;
 done;
done
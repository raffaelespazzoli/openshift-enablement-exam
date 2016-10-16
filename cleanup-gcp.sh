#!/bin/bash

set -e
gcloud config set project $GCLOUD_PROJECT

#delete google storage buckets
for i in $(gsutil ls); do
	gsutil rm -r $i &
done;
wait

#delete firewall rules
for i in $(gcloud compute firewall-rules list -r oc | awk 'NR>1 {print $1}'); do
	gcloud compute firewall-rules delete -q $i &
done;
wait

#delete forwarding rules
for i in $(gcloud compute forwarding-rules list | awk 'NR>1 {print $1}'); do
	gcloud compute forwarding-rules delete -q $i --region "us-central1" &
done;
wait

#delete target pools
for i in $(gcloud compute target-pools list | awk 'NR>1 {print $1}'); do
	gcloud compute target-pools delete -q $i --region "us-central1" &
done;
wait

#delete static address
for i in $(gcloud compute addresses list | awk 'NR>1 {print $1}'); do
	gcloud compute addresses delete -q $i --region "us-central1" &
done;
wait

#delete backend-services
for i in $(gcloud beta compute backend-services list | awk 'NR>1 {print $1}'); do
	gcloud beta compute backend-services delete -q $i --region "us-central1" &
done;
wait

#delete health checks
for i in $(gcloud compute health-checks list | awk 'NR>1 {print $1}'); do
	gcloud compute health-checks delete -q $i &
done;
wait

#delete instance-groups
for k in us-central1-a us-central1-b us-central1-c; do
	for i in $(gcloud compute instance-groups unmanaged list --zones $k | awk 'NR>1 {print $1}'); do
		gcloud compute instance-groups unmanaged delete -q $i --zone $k &
	done;
done;
wait

#delete VMs
for k in us-central1-a us-central1-b us-central1-c; do
	for i in $(gcloud compute instances list --zones $k| awk 'NR>1 {print $1}'); do
		gcloud compute instances delete $i -q --zone "$k" &
	done;
done;
wait


#delete disks
for k in us-central1-a us-central1-b us-central1-c; do
	for i in $(gcloud compute disks list --zones $k | awk 'NR>1 {print $1}'); do
		gcloud compute disks delete -q $i --zone $k &
	done;
done
wait


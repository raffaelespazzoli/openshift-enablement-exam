#!/bin/bash

set -e
gcloud config set project $GCLOUD_PROJECT

#echo "delete google storage buckets"
#delete google storage buckets
for i in $(gsutil ls); do
	gsutil rm -r $i &
done;
wait

#echo "delete firewall rules"
#delete firewall rules
for i in $(gcloud compute firewall-rules list --filter="name~'^oc-.*'" | awk 'NR>1 {print $1}'); do
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
for k in us-central1-a us-central1-b us-central1-f; do
	for i in $(gcloud compute instance-groups unmanaged list --filter="zone:( $k )" | awk 'NR>1 {print $1}'); do
		gcloud compute instance-groups unmanaged delete -q $i --zone $k &
	done;
done;
wait

#delete VMs
for k in us-central1-a us-central1-b us-central1-f; do
	for i in $(gcloud compute instances list --filter="zone:( $k )" | awk 'NR>1 {print $1}'); do
		gcloud compute instances delete $i -q --zone "$k" &
	done;
done;
wait


#delete disks
for k in us-central1-a us-central1-b us-central1-f; do
	for i in $(gcloud compute disks list --filter="zone:( $k )" | awk 'NR>1 {print $1}'); do
		gcloud compute disks delete -q $i --zone $k &
	done;
done
wait

#empty but not dns zone (propagation of a new zone is too slow for practical purposes)
touch empty-file
gcloud dns record-sets import -z "$GCLOUD_PROJECT" --delete-all-existing empty-file
rm empty-file
#gcloud dns managed-zones delete "$GCLOUD_PROJECT"


#!/bin/bash

set -e
gcloud config set project $GCLOUD_PROJECT

#delete forwarding rules
for i in $(gcloud compute forwarding-rules list | awk 'NR>1 {print $1}') do
	gcloud compute forwarding-rules delete $i;
done

#delete target pools
for i in $(gcloud compute target-pools list | awk 'NR>1 {print $1}') do
	gcloud compute target-pools delete $i;
done

#delete static address
for i in $(gcloud compute addresses list | awk 'NR>1 {print $1}') do
	gcloud compute addresses delete $i;
done

#delete VMs
for i in $(gcloud compute instances list | awk 'NR>1 {print $1}') do
	gcloud compute instances delete $i;
done

#delete disks
for i in $(gcloud compute disks list | awk 'NR>1 {print $1}') do
	gcloud compute disks delete $i;
done
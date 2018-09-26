#!/bin/bash

set -e
[  -z "$OCP_VERSION" ] && OCP_VERSION=3.10
[  -z "$RHEL_VERSION" ] && RHEL_VERSION=`gcloud compute images list | awk '{print $1}' | grep rhel-7-v`
[  -z "$OCP_MASTER_COUNT" ] && OCP_MASTER_COUNT=1
[  -z "$OCP_INFRA_COUNT" ] && OCP_INFRA_COUNT=1
[  -z "$OCP_NODE_COUNT" ] && OCP_NODE_COUNT=2

DEFAULT_SCOPE="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write"

echo "RHEL_VERSION == $RHEL_VERSION"

gcloud config set project $GCLOUD_PROJECT


####################################################################################
#
# Create the docker disk storage for INFRA and NODE
#
####################################################################################
for (( I=1; I<=$OCP_INFRA_COUNT; I++ ))
do
   echo $I
   [ $I == "1" ] && ZONE=us-central1-a
   [ $I == "2" ] && ZONE=us-central1-b
   [ $I == "3" ] && ZONE=us-central1-f
   gcloud compute disks create "infranode$I-docker" --size "50" --zone "$ZONE" --type "pd-standard" &
done

for (( I=1; I<=$OCP_NODE_COUNT; I++ ))
do
   [ $I == "1" ] && ZONE=us-central1-a
   [ $I == "2" ] && ZONE=us-central1-b
   [ $I == "3" ] && ZONE=us-central1-f
   gcloud compute disks create "node$I-docker" --size "50" --zone "$ZONE" --type "pd-standard" &
done

wait
####################################################################################



####################################################################################
#
# Create the MASTER, INFRA, and COMPUTE Nodes
#
####################################################################################
for (( I=1; I<=$OCP_MASTER_COUNT; I++ ))
do
   [ $I == "1" ] && ZONE=us-central1-a
   [ $I == "2" ] && ZONE=us-central1-b
   [ $I == "3" ] && ZONE=us-central1-f
   gcloud compute instances create "master$I"\
     --zone "$ZONE"\
     --machine-type "n1-standard-2"\
     --subnet "default"\
     --maintenance-policy "TERMINATE"\
     --service-account default\
     --scopes "$DEEFAULT_SCOPE"\
     --image-project "rhel-cloud"\
     --image "$RHEL_VERSION"\
     --boot-disk-size "50"\
     --boot-disk-type "pd-standard"\
     --boot-disk-device-name "master$I"\
     --tags "master" &
done

for (( I=1; I<=$OCP_INFRA_COUNT; I++ ))
do
   [ $I == "1" ] && ZONE=us-central1-a
   [ $I == "2" ] && ZONE=us-central1-b
   [ $I == "3" ] && ZONE=us-central1-f
   gcloud compute instances create "infranode$I"\
     --zone "$ZONE"\
     --machine-type "n1-standard-2"\
     --subnet "default"\
     --maintenance-policy "TERMINATE"\
     --service-account default\
     --scopes "$DEFAULT_SCOPE"\
     --disk "name=infranode$I-docker,device-name=disk-1,mode=rw,boot=no"\
     --image-project "rhel-cloud"\
     --image "$RHEL_VERSION"\
     --boot-disk-size "20"\
     --boot-disk-type "pd-standard"\
     --boot-disk-device-name "infranode$I"\
     --tags "infranode" &
done

for (( I=1; I<=$OCP_NODE_COUNT; I++ ))
do
   [ $I == "1" ] && ZONE=us-central1-a
   [ $I == "2" ] && ZONE=us-central1-b
   [ $I == "3" ] && ZONE=us-central1-f
   gcloud compute instances create "node$I"\
     --zone "$ZONE"\
     --machine-type "n1-standard-2"\
     --subnet "default"\
     --maintenance-policy "TERMINATE"\
     --service-account default\
     --scopes "$DEFAULT_SCOPE"\
     --disk "name=node$I-docker,device-name=disk-1,mode=rw,boot=no"\
     --image-project "rhel-cloud"\
     --image "$RHEL_VERSION"\
     --boot-disk-size "20"\
     --boot-disk-type "pd-standard"\
     --boot-disk-device-name "node$I"\
     --tags "node" &
done

wait
####################################################################################



####################################################################################
#
# create static addresses
#
####################################################################################
gcloud compute addresses create "master-external" --region "us-central1" &
gcloud compute addresses create "infranode-external" --region "us-central1" &
gcloud compute addresses create "ose-bastion" --region "us-central1" &
wait

####################################################################################
#
# create health checks
#
####################################################################################
gcloud compute health-checks create https master-health-check --port 8443 --request-path /healthz
gcloud compute health-checks create http router-health-check --port 80 --request-path /

####################################################################################
#
# create target pools
#
####################################################################################
gcloud compute target-pools create master-pool --region us-central1 &
gcloud compute target-pools create infranode-pool --region us-central1 &
wait


####################################################################################
#
# Create the MASTER and INFRA POOLS
#
####################################################################################
for (( I=1; I<=$OCP_MASTER_COUNT; I++ ))
do
   [ $I == "1" ] && ZONE=us-central1-a
   [ $I == "2" ] && ZONE=us-central1-b
   [ $I == "3" ] && ZONE=us-central1-f
   gcloud compute target-pools add-instances master-pool --instances master$I --instances-zone $ZONE &
done

for (( I=1; I<=$OCP_INFRA_COUNT; I++ ))
do
   [ $I == "1" ] && ZONE=us-central1-a
   [ $I == "2" ] && ZONE=us-central1-b
   [ $I == "3" ] && ZONE=us-central1-f
   gcloud compute target-pools add-instances infranode-pool --instances infranode$I --instances-zone $ZONE &
done

wait

####################################################################################
#
# create instance groups
#
####################################################################################
for (( I=1; I<=$OCP_MASTER_COUNT; I++ ))
do
   [ $I == "1" ] && ZONE=us-central1-a
   [ $I == "2" ] && ZONE=us-central1-b
   [ $I == "3" ] && ZONE=us-central1-f
   gcloud compute instance-groups unmanaged create master$I --zone $ZONE &
done

wait

for (( I=1; I<=$OCP_MASTER_COUNT; I++ ))
do
   [ $I == "1" ] && ZONE=us-central1-a
   [ $I == "2" ] && ZONE=us-central1-b
   [ $I == "3" ] && ZONE=us-central1-f
   gcloud compute instance-groups unmanaged add-instances master$I --instances master$I --zone $ZONE &
done

wait

####################################################################################
#
# Create the Firewall Rules
#
####################################################################################
gcloud compute firewall-rules create "oc-master" --allow tcp:8443 --network "default" --source-ranges "0.0.0.0/0" --target-tags "master"
gcloud compute firewall-rules create "oc-infranode" --allow tcp:80,tcp:443 --network "default" --source-ranges "0.0.0.0/0" --target-tags "infranode"

####################################################################################
#
# Create back-end service
#
####################################################################################
gcloud beta compute backend-services create master-internal --load-balancing-scheme internal --region us-central1 --protocol tcp --port-name "oc-master" --health-checks master-health-check

for (( I=1; I<=$OCP_MASTER_COUNT; I++ ))
do
   [ $I == "1" ] && ZONE=us-central1-a
   [ $I == "2" ] && ZONE=us-central1-b
   [ $I == "3" ] && ZONE=us-central1-f
   gcloud beta compute backend-services add-backend master-internal --instance-group master$I --instance-group-zone $ZONE --region us-central1
done

#create load balancers
gcloud compute forwarding-rules create master-external --region us-central1 --ports 8443 --address `gcloud compute addresses list | grep master-external | awk '{print $3}'` --target-pool master-pool &
gcloud compute forwarding-rules create infranode-external-443 --region us-central1 --ports 443 --address `gcloud compute addresses list | grep infranode-external | awk '{print $3}'` --target-pool infranode-pool &
gcloud compute forwarding-rules create infranode-external-80 --region us-central1 --ports 80 --address `gcloud compute addresses list | grep infranode-external | awk '{print $3}'`  --target-pool infranode-pool &
gcloud beta compute forwarding-rules create master-internal --load-balancing-scheme internal --ports 8443 --region us-central1 --backend-service master-internal &
wait

#ose-bastion
gcloud compute instances create "ose-bastion"\
  --zone "us-central1-a"\
  --machine-type "n1-standard-2"\
  --subnet "default"\
  --maintenance-policy "TERMINATE"\
  --service-account default\
  --scopes "https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/compute.readonly","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/trace.append"\
  --image-project "rhel-cloud"\
  --image "$RHEL_VERSION"\
  --boot-disk-size "20"\
  --boot-disk-type "pd-standard"\
  --boot-disk-device-name "ose-bastion"\
  --address `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'`

#create storage for registry
gsutil mb -c Standard -l us-central1 -p $GCLOUD_PROJECT gs://$GCLOUD_PROJECT-registry

#create dns zone only if it already does not exists
if [[ `gcloud dns managed-zones list | grep $DNS_DOMAIN | wc -l` -ne 1  ]]; then
gcloud dns managed-zones create --dns-name="$DNS_DOMAIN" --description="A zone" "$GCLOUD_PROJECT"
fi

# add records to dns zone
gcloud dns record-sets transaction start -z="$GCLOUD_PROJECT"
gcloud dns record-sets transaction add -z="$GCLOUD_PROJECT" --name="master.$DNS_DOMAIN" --type=A --ttl=300 `gcloud compute addresses list | grep master-external | awk '{print $3}'`
gcloud dns record-sets transaction add -z="$GCLOUD_PROJECT" --name="*.apps.$DNS_DOMAIN" --type=A --ttl=300 `gcloud compute addresses list | grep infranode-external | awk '{print $3}'`
gcloud dns record-sets transaction add -z="$GCLOUD_PROJECT" --name="master-internal.$DNS_DOMAIN" --type=A --ttl=300 `gcloud compute forwarding-rules list master-internal | awk 'NR>1 {print $3}'`
gcloud dns record-sets transaction add -z="$GCLOUD_PROJECT" --name="mi.$DNS_DOMAIN" --type=A --ttl=300 `gcloud compute forwarding-rules list master-internal | awk 'NR>1 {print $3}'`
gcloud dns record-sets transaction execute -z="$GCLOUD_PROJECT"



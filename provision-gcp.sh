#!/bin/bash

set -e
gcloud config set project $GCLOUD_PROJECT

#create docker disks
gcloud compute disks create "infranode1-docker" --size "50" --zone "us-central1-a" --type "pd-standard" &
gcloud compute disks create "infranode2-docker" --size "50" --zone "us-central1-b" --type "pd-standard" &
gcloud compute disks create "infranode3-docker" --size "50" --zone "us-central1-f" --type "pd-standard" &
gcloud compute disks create "node1-docker" --size "50" --zone "us-central1-a" --type "pd-standard" &
gcloud compute disks create "node2-docker" --size "50" --zone "us-central1-b" --type "pd-standard" &
gcloud compute disks create "node3-docker" --size "50" --zone "us-central1-f" --type "pd-standard" &
wait

if [ $GLUSTER == "yes" ]; then 

	#create gluster disks
	gcloud compute disks create "node1-gluster" --size "200" --zone "us-central1-a" --type "pd-standard" &
	gcloud compute disks create "node2-gluster" --size "200" --zone "us-central1-b" --type "pd-standard" &
	gcloud compute disks create "node3-gluster" --size "200" --zone "us-central1-f" --type "pd-standard" &
	wait
fi

#Masters
gcloud compute instances create "master1" --zone "us-central1-a" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "50" --boot-disk-type "pd-standard" --boot-disk-device-name "master1" --tags "master" &
gcloud compute instances create "master2" --zone "us-central1-b" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "50" --boot-disk-type "pd-standard" --boot-disk-device-name "master2" --tags "master" &
gcloud compute instances create "master3" --zone "us-central1-f" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "50" --boot-disk-type "pd-standard" --boot-disk-device-name "master3" --tags "master" &

if [ $GLUSTER == "yes" ]; then 
	
	#nodes
	gcloud compute instances create "node1" --zone "us-central1-a" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --disk "name=node1-docker,device-name=disk-1,mode=rw,boot=no" --disk "name=node1-gluster,device-name=disk-2,mode=rw,boot=no" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "50" --boot-disk-type "pd-standard" --boot-disk-device-name "node1" &
	gcloud compute instances create "node2" --zone "us-central1-b" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --disk "name=node2-docker,device-name=disk-1,mode=rw,boot=no" --disk "name=node2-gluster,device-name=disk-2,mode=rw,boot=no" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "50" --boot-disk-type "pd-standard" --boot-disk-device-name "node2" &
	gcloud compute instances create "node3" --zone "us-central1-f" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --disk "name=node3-docker,device-name=disk-1,mode=rw,boot=no" --disk "name=node3-gluster,device-name=disk-2,mode=rw,boot=no" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "50" --boot-disk-type "pd-standard" --boot-disk-device-name "node3" &
	wait
			
else

	#infranodes
	gcloud compute instances create "infranode1" --zone "us-central1-a" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --disk "name=infranode1-docker,device-name=disk-1,mode=rw,boot=no" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "20" --boot-disk-type "pd-standard" --boot-disk-device-name "infranode1" --tags "infranode" &
	gcloud compute instances create "infranode2" --zone "us-central1-b" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --disk "name=infranode2-docker,device-name=disk-1,mode=rw,boot=no" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "20" --boot-disk-type "pd-standard" --boot-disk-device-name "infranode2" --tags "infranode" &
	gcloud compute instances create "infranode3" --zone "us-central1-f" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --disk "name=infranode3-docker,device-name=disk-1,mode=rw,boot=no" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "20" --boot-disk-type "pd-standard" --boot-disk-device-name "infranode3" --tags "infranode" &

	
	#nodes
	gcloud compute instances create "node1" --zone "us-central1-a" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --disk "name=node1-docker,device-name=disk-1,mode=rw,boot=no" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "20" --boot-disk-type "pd-standard" --boot-disk-device-name "node1" &
	gcloud compute instances create "node2" --zone "us-central1-b" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --disk "name=node2-docker,device-name=disk-1,mode=rw,boot=no" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "20" --boot-disk-type "pd-standard" --boot-disk-device-name "node2" &
	gcloud compute instances create "node3" --zone "us-central1-f" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/devstorage.read_write" --disk "name=node3-docker,device-name=disk-1,mode=rw,boot=no" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "20" --boot-disk-type "pd-standard" --boot-disk-device-name "node3" &
	wait

fi

# create static addresses
gcloud compute addresses create "master-external" --region "us-central1" &
gcloud compute addresses create "infranode-external" --region "us-central1" &
gcloud compute addresses create "ose-bastion" --region "us-central1" &
wait

# create health checks
gcloud compute health-checks create https master-health-check --port 8443 --request-path /healthz
gcloud compute health-checks create http router-health-check --port 80 --request-path /

# create target pools
gcloud compute target-pools create master-pool --region us-central1 &
gcloud compute target-pools create infranode-pool --region us-central1 &
wait

gcloud compute target-pools add-instances master-pool --instances master1 --instances-zone us-central1-a &
gcloud compute target-pools add-instances master-pool --instances master2 --instances-zone us-central1-b &
gcloud compute target-pools add-instances master-pool --instances master3 --instances-zone us-central1-f &
gcloud compute target-pools add-instances infranode-pool --instances infranode1 --instances-zone us-central1-a &
gcloud compute target-pools add-instances infranode-pool --instances infranode2 --instances-zone us-central1-b &
gcloud compute target-pools add-instances infranode-pool --instances infranode3 --instances-zone us-central1-f &
wait

#create instance groups
gcloud compute instance-groups unmanaged create master1 --zone us-central1-a &
gcloud compute instance-groups unmanaged create master2 --zone us-central1-b &
gcloud compute instance-groups unmanaged create master3 --zone us-central1-f &
wait

gcloud compute instance-groups unmanaged add-instances master1 --instances master1 --zone us-central1-a &
gcloud compute instance-groups unmanaged add-instances master2 --instances master2 --zone us-central1-b &
gcloud compute instance-groups unmanaged add-instances master3 --instances master3 --zone us-central1-f &
wait

#create back-end service
gcloud beta compute backend-services create master-internal --load-balancing-scheme internal --region us-central1 --protocol tcp --port 8443 --health-checks master-health-check

gcloud beta compute backend-services add-backend master-internal --instance-group master1 --instance-group-zone us-central1-a --region us-central1 
gcloud beta compute backend-services add-backend master-internal --instance-group master2 --instance-group-zone us-central1-b --region us-central1 
gcloud beta compute backend-services add-backend master-internal --instance-group master3 --instance-group-zone us-central1-f --region us-central1 


#create load balancers
gcloud compute forwarding-rules create master-external --region us-central1 --ports 8443 --address `gcloud compute addresses list | grep master-external | awk '{print $3}'` --target-pool master-pool &
gcloud compute forwarding-rules create infranode-external-443 --region us-central1 --ports 443 --address `gcloud compute addresses list | grep infranode-external | awk '{print $3}'` --target-pool infranode-pool &
gcloud compute forwarding-rules create infranode-external-80 --region us-central1 --ports 80 --address `gcloud compute addresses list | grep infranode-external | awk '{print $3}'`  --target-pool infranode-pool &
gcloud beta compute forwarding-rules create master-internal --load-balancing-scheme internal --ports 8443 --region us-central1 --backend-service master-internal &
wait

#create firewall rules
gcloud compute firewall-rules create "oc-master" --allow tcp:8443 --network "default" --source-ranges "0.0.0.0/0" --target-tags "master"
gcloud compute firewall-rules create "oc-infranode" --allow tcp:80,tcp:443 --network "default" --source-ranges "0.0.0.0/0" --target-tags "infranode"

#ose-bastion
gcloud compute instances create "ose-bastion" --zone "us-central1-a" --machine-type "n1-standard-2" --preemptible --subnet "default" --maintenance-policy "TERMINATE" --scopes default="https://www.googleapis.com/auth/devstorage.read_only","https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring.write","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/compute.readonly","https://www.googleapis.com/auth/compute","https://www.googleapis.com/auth/trace.append" --image-project "rhel-cloud" --image "rhel-7-v20170816" --boot-disk-size "20" --boot-disk-type "pd-standard" --boot-disk-device-name "ose-bastion" --address `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'`

#create storage for registry
gsutil mb -c Standard -l us-central1 -p $GCLOUD_PROJECT gs://$GCLOUD_PROJECT-registry

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

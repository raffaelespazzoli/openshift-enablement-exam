# openshift-enablement-exam

The following instructions will setup an OpenShift OCP 3.3 environment on Google Cloud compliant with the following reference architecture.

![GCP reference architecture](/media/OSE-on-GCE-Architecture v0.3.png)

## Gcloud provisioning


Clone this project

```
git clone https://github.com/raffaelespazzoli/openshift-enablement-exam
cd openshift-enablement-exam
```

Create a [new google cloud project](https://cloud.google.com/resource-manager/docs/creating-project).

install the [command line tool](https://cloud.google.com/sdk/downloads).

[initialize and authenticate in gcloud](https://cloud.google.com/sdk/docs/authorizing).

In order to run this provisioning script you will need to be able to run 34vCPU in the US central region. You may need to increase your [resource quota](https://cloud.google.com/compute/docs/resource-quotas).

Enable your project to use the compute api by visiting the [compute engine](https://console.cloud.google.com/home) menu item (there is probably a better way to do it).

Set you google project configurations
```
export GCLOUD_PROJECT=<your project>
export SSH_PUB_KEY=<the ssh pub key you want to use> #usually $HOME/.ssh/id_rsa.pub
```

Run the provisioning script.

```
./provision-gcp.sh
```
This will take some time.

## Prepare the bastion host

Set you RHN account credentials.
```
export RHN_USERNAME=rhn-gps-rspazzol
export RHN_PASSWORD=xxx 
```
Run the prepare bastion script.
```
./prepare-bastion.sh
```

## Prepare the cluster

Shell in the bastion host
```
ssh -o SendEnv RHN_USERNAME -o SendEnv RHN_PASSWORD \`gcloud compute instance describe ose-bastion region us-central1 | grep address: | awk '{print $2}'\`
```
Run the prepare cluster script
```
./prepare-cluster.sh
```

## Setup openshift

prepare the inventory file by running the following:
```
sed -i -- 's/master.10.128.0.10.xip.io/master.\`gcloud compute instance describe master-internal region us-central1 | grep address: | awk '{print $2}'\`.xip.io/g' hosts
sed -i -- 's/master.104.197.199.131.xip.io/master.\`gcloud compute instance describe master-external region us-central1 | grep address: | awk '{print $2}'\`.xip.io/g' hosts
sed -i -- 's/apps.104.198.35.122.xip.io/apps.\`gcloud compute instance describe infranode-external region us-central1 | grep address: | awk '{print $2}'\`.xip.io/g' hosts
```

Run the ansible playbook
```
ansible-playbook -v -i hosts /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
```
## Clean up

To clean up your Google Cloud project type the following:
```
./cleanup-gcp.sh
```

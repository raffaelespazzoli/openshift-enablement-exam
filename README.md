# openshift-enablement-exam

## Gcloud provisioning

Download this project

```
git clone https://github.com/raffaelespazzoli/openshift-enablement-exam
cd openshift-enablement-exam
```

Create a [new google cloud project](https://cloud.google.com/resource-manager/docs/creating-project).

install the [command line tool](https://cloud.google.com/sdk/downloads).

[initialize and authenticate in gcloud](https://cloud.google.com/sdk/docs/authorizing).

In order to run this provisioning script you may need to increase your [resource quota](https://cloud.google.com/compute/docs/resource-quotas).

```
export GCLOUD_PROJECT=<your project>
```

Run the provisioning script.

```
./provision-gcp.sh
```

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

Run the ansible playbook
```
ansible-playbook -v -i hosts /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
```


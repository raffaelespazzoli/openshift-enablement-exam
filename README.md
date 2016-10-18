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

Install the [command line tool](https://cloud.google.com/sdk/downloads).

[Initialize and authenticate in gcloud](https://cloud.google.com/sdk/docs/authorizing).

In order to run this provisioning script you will need to be able to run 34vCPU in the US central region. You may need to increase your [resource quota](https://cloud.google.com/compute/docs/resource-quotas).

Enable your project to use the compute api by visiting the [compute engine](https://console.cloud.google.com/home) menu item (there is probably a better way to do it).

Set your google project configuration
```
export GCLOUD_PROJECT=<your project>
```
set your dns zone (es: exam.example.com)
your master will be available at `master.exam.example.com` and the routes will have the form `*.apps.exam.example.com`.

you need to externally configure your domain to point to google cloud dns. More explanations [here] (https://cloud.google.com/dns/update-name-servers)
```
export DNS_DOMAIN=<your domain>
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
define which key you want to use, this key must be available to the following ssh commands
```
export SSH_PUB_KEY=<the ssh pub key you want to use> #usually $HOME/.ssh/id_rsa.pub
```
Run the prepare bastion script.
```
./prepare-bastion.sh
```

## Prepare the cluster

Shell in the bastion host
```
ssh -o SendEnv=RHN_USERNAME -o SendEnv=RHN_PASSWORD -o SendEnv=DNS_DOMAIN `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'`
cd openshift-enablement-exam
```
Run the prepare cluster script
```
./prepare-cluster.sh
```

## Setup openshift

If you're using xip.io, prepare the inventory file by running the following:
```
sed -i "s/master.10.128.0.10.xip.io/master.`gcloud compute forwarding-rules list master-internal | awk 'NR>1 {print $3}'`.xip.io/g" hosts
sed -i "s/master.104.197.199.131.xip.io/master.`gcloud compute addresses list | grep master-external | awk '{print $3}'`.xip.io/g" hosts
sed -i "s/apps.104.198.35.122.xip.io/apps.`gcloud compute addresses list | grep infranode-external | awk '{print $3}'`.xip.io/g" hosts
```
if you're using a real dns server do the following:
```
sed -i "s/master.10.128.0.10.xip.io/master-internal.$DNS_DOMAIN/g" hosts
sed -i "s/master.104.197.199.131.xip.io/master.$DNS_DOMAIN/g" hosts
sed -i "s/apps.104.198.35.122.xip.io/apps.$DNS_DOMAIN/g" hosts
```


Run the ansible playbook
```
ansible-playbook -v -i hosts /usr/share/ansible/openshift-ansible/playbooks/byo/config.yml
```

There seems to be an [issue](https://github.com/openshift/openshift-ansible/issues/2553) with the standard ansible script. If you experience it, the latest from the openshift-ansible github works. 
Reprovision your cluster and then type the following:

```
cd ..
git clone https://github.com/openshift/openshift-ansible
ansible-playbook -v -i ./openshift-enablement-exam/hosts ./openshift-ansible/playbooks/byo/config.yml
```

## Creating new users

From the bastion host run the following
```
ansible 'masters' -i hosts -b -m shell -a "htpasswd -b /etc/origin/master/htpasswd <username> <password>"
```
## Clean up

To clean up your Google Cloud project type the following:
```
./cleanup-gcp.sh
```
This may take some time.

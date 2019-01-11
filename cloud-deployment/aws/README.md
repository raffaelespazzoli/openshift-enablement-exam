export AWS_PROFILE=raffaelespazzoli

create an instance and run the following:
subscription-manager register --username=$RHN_USERNAME --password=$RHN_PASSWORD && subscription-manager attach --pool=$RHN_SUB_POOL && subscription-manager refresh
subscription-manager repos --disable='*' && subscription-manager repos --enable=rhel-7-server-rpms --enable=rhel-7-server-optional-rpms --enable=rhel-7-server-extras-rpms --enable=rhel-7-server-ose-3.11-rpms --enable=rhel-7-fast-datapath-rpms --enable=rhel-7-server-ansible-2.6-rpms
yum update -y

save the instance as a new ami

ansible-playbook -vv -i inventory ~/git/openshift-ansible/playbooks/aws/openshift-cluster/prerequisites.yml --private-key=~/.ssh/sshkey-gcp
ansible-playbook -vv -i inventory ~/git/openshift-ansible/playbooks/aws/openshift-cluster/build_ami.yml --private-key=~/.ssh/sshkey-gcp
ansible-playbook -i inventory ~/git/openshift-ansible/playbooks/aws/openshift-cluster/provision.yml --private-key=~/.ssh/sshkey-gcp -vv
ansible-playbook -i inventory ~/git/openshift-ansible/playbooks/aws/openshift-cluster/install.yml --private-key=~/.ssh/sshkey-gcp -vv
ansible-playbook -i inventory ~/git/openshift-ansible/playbooks/aws/openshift-cluster/provision_nodes.yml --private-key=~/.ssh/sshkey-gcp -vv
ansible-playbook -i inventory ~/git/openshift-ansible/playbooks/aws/openshift-cluster/accept.yml --private-key=~/.ssh/sshkey-gcp -vv

 - "rhel-7-server-rpms"
 - "rhel-7-server-ose-3.11-rpms"
 - "rhel-7-server-extras-rpms"
 - "rhel-7-fast-datapath-rpms"
 - "rhel-7-server-optional-rpms"
 - "rhel-7-server-ansible-2.6-rpms"

cd /home/rspazzol/git/casl-ansible/
ansible-galaxy install -r casl-requirements.yml -p roles

sudo setenforce 0
      
docker run -u `id -u` \
      -v $HOME/.ssh/rspazzol-etl3.pem:/opt/app-root/src/.ssh/rspazzol-etl3.pem:ro \
      -v $HOME/.config/openstack/:/opt/app-root/src/.config/openstack:ro \
      -v $HOME/git:/tmp/git:Z \
      -e INVENTORY_DIR=/tmp/git/openshift-enablement-exam/misc/casl/inventory \
      -e PLAYBOOK_FILE=/tmp/git/casl-ansible/playbooks/openshift/end-to-end.yml \
      -e OPTS="-e openstack_ssh_public_key=rspazzol-etl3" -ti \
      redhatcop/installer-openstack /bin/bash           
      
docker run -it --name control-host -v $HOME/.ssh:/root/.ssh -v $HOME/.config/openstack:/root/.config/openstack -v $HOME/git:/tmp/git:Z -v $HOME/git/openshift-enablement-exam/misc/casl/misc/ansible.cfg:/root/.ansible.cfg docker.io/redhatcop/control-host-openstack bash      

export ANSIBLE_CONFIG=/etc/ansible/ansible.cfg

openstack stack delete -y env1.casl.raffa.com

ansible-playbook -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory   /tmp/git/casl-ansible/playbooks/openshift/end-to-end.yml --private-key=~/.ssh/rspazzol-etl3.pem -e openstack_ssh_public_key=rspazzol

ansible-playbook -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory   /tmp/git/openshift-ansible/playbooks/byo/config.yml --private-key=~/.ssh/rspazzol-etl2.pem -e openstack_ssh_public_key=rspazzol-etl2

ansible-playbook -vv -i /tmp/git/openshift-enablement-exam/misc/casl/inventory   /tmp/git/openshift-ansible/playbooks/byo/openshift-node/config.yml --private-key=~/.ssh/rspazzol-etl2.pem -e openstack_ssh_public_key=rspazzol-etl2

ansible nodes -vv -b -i /tmp/git/openshift-enablement-exam/misc/casl/inventory -m shell -a "<command>" --private-key=~/.ssh/rspazzol-etl2.pem -e openstack_ssh_public_key=rspazzol-etl2

ansible nodes -vv -b -i /tmp/git/openshift-enablement-exam/misc/casl/inventory -m shell -a "rm -rf /etc/origin/node && rm -rf /etc/origin/generated-configs" --private-key=~/.ssh/rspazzol-etl2.pem -e openstack_ssh_public_key=rspazzol-etl2

ansible nodes -vv -b -i /tmp/git/openshift-enablement-exam/misc/casl/inventory -m shell -a "rm -rf /etc/origin && rm -rf /var/lib/etcd && rm -rf /var/lib/etcd" --private-key=~/.ssh/rspazzol-etl2.pem -e openstack_ssh_public_key=rspazzol-etl2







developing with git

git checkout master
git fetch upstream
git rebase upstream/master
git push

git checkout <branch>
git rebase master
git push --force [--set-upstream origin <branch>]

when adding multiple interfaces:
ansible -vv -i /root/code/openshift-enablement-exam/misc/casl/inventory nodes,targetd -m copy -a "src=/root/code/openshift-enablement-exam/misc/casl/ifcfg-eth1 dest=/etc/sysconfig/network-scripts" -e openstack_ssh_public_key=rspazzol-etl2 --private-key=.ssh/rspazzol-etl2.pem
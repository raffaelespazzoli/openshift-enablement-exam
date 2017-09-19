
cd /home/rspazzol/git/casl-ansible/
ansible-galaxy install -r casl-requirements.yml -p roles
cd docker/control-host-openstack
sudo setenforce 0
docker-compose up -d
docker exec -it controlhostopenstack_control-host_1 bash
openstack stack delete -y env1.casl.raffa.com
ansible-playbook -vv -i /root/code/casl-ansible/inventory/raffa.casl.example.com/inventory /root/code/casl-ansible/playbooks/openshift/end-to-end.yml -e openstack_ssh_public_key=rspazzol-etl --private-key=.ssh/rspazzol-etl.pem



developing with git

git checkout master
git fetch upstream
git rebase upstream/master
git push

git checkout <branch>
git rebase master
git push --force


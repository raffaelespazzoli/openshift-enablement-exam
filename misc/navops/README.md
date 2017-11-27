Installation
curl -o navopsctl http://storage.googleapis.com/navops/demo/navopsctl/latest/linux/amd64/navopsctl
curl https://navops.io/install/navops-command?token=rspazzol@redhat.com%3A362672312\&registry=demo.navops.io > navops-command.yaml
oc adm policy add-scc-to-user anyuid -z default

account
admin/navops

on IDM integration: manual provisioning of users
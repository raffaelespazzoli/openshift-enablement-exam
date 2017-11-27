#creating an iscsi server

some context https://access.redhat.com/solutions/2149241
on your bastion host
```
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo yum install -y targetcli
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo targetcli /backstores/fileio/ create file1 /root/disk1_file 100M
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo targetcli /iscsi/ create iqn.2012-02.systems.raffa.gc:remotedisk1
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo targetcli /iscsi/iqn.2012-02.systems.raffa.gc:remotedisk1/tpg1/acls/ create iqn.2017-02.systems.raffa.gc:ocp
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo targetcli /iscsi/iqn.2012-02.systems.raffa.gc:remotedisk1/tpg1/luns/ create /backstores/fileio/file1
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo targetcli saveconfig
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo targetcli ls
```
check the configuration:
initiator `iqn.2012-02.systems.raffa.gc:ocp` should be enabled to connect to `0.0.0.0:3260` to the target `iqn.2012-02.systems.raffa.gc:remotedisk1` `tpg1` and `lun0`.
make sure 3260 is open from a firewall perspective

```
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo firewall-cmd --add-port=3260/tcp
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo firewall-cmd --add-port=3260/tcp --permanent
```
enable the iscsi storage service
```
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo systemctl enable target
ssh -t `gcloud compute addresses list | grep ose-bastion | awk '{print $3}'` sudo systemctl start target
```
now your iscsi device should be available

#enable the initiators

```
ansible nodes -b -i hosts -m shell -a "yum -y install iscsi-initiator-utils"
ansible nodes -b -i hosts -m shell -a "echo InitiatorName=iqn.2017-02.systems.raffa.gc:ocp > /etc/iscsi/initiatorname.iscsi"
ansible nodes -b -i hosts -m shell -a "iscsiadm -m iface -I tcp -o new"
ansible nodes -b -i hosts -m shell -a "iscsiadm -m iface -I tcp -o update -n iface.net_ifacename -v eth0"
#ansible nodes -b -i hosts -m shell -a "systemctl start iscsid"
#ansible nodes -b -i hosts -m shell -a "systemctl enable iscsid"

```
#create the persistent volume
```
oc create -f iscsi-pv.yaml
```
#test the volume
```
oc new-project iscsi-test
oc create -f iscsi-pv-claim.yaml
oc create -f iscsi-pvc-pod.yaml
```


#current error
```
Feb 22 01:13:56 rhel-cdk sh[3546]: E0222 01:13:56.248708    3714 iscsi_util.go:112] iscsi: failed to sendtargets to portal 10.1.2.1:3260 error:
Feb 22 01:13:56 rhel-cdk sh[3546]: E0222 01:13:56.248755    3714 disk_manager.go:50] failed to attach disk
Feb 22 01:13:56 rhel-cdk sh[3546]: E0222 01:13:56.248762    3714 iscsi.go:194] iscsi: failed to setup
Feb 22 01:13:56 rhel-cdk sh[3546]: E0222 01:13:56.248863    3714 nestedpendingoperations.go:233] Operation for "\"kubernetes.io/iscsi/da84011c-f8bf-11e6-a001-5254007f3655-iscsi-vol1\" (\"da84011c-f8bf-11e6-a001-5254007f3655\")" failed. No retries permitted until 2017-02-22 01:15:56.248830534 -0500 EST (durationBeforeRetry 2m0s). Error: MountVolume.SetUp failed for volume "kubernetes.io/iscsi/da84011c-f8bf-11e6-a001-5254007f3655-iscsi-vol1" (spec.Name: "iscsi-pv") pod "da84011c-f8bf-11e6-a001-5254007f3655" (UID: "da84011c-f8bf-11e6-a001-5254007f3655") with: executable file not found in $PATH
```

```
[root@rhel-cdk iscsi]# iscsiadm -m discovery -t sendtargets -p 10.1.2.1 -I 10.1.2.2
iscsiadm: Could not read iface info for 10.1.2.2. Make sure a iface config with the file name and iface.iscsi_ifacename 10.1.2.2 is in /var/lib/iscsi/ifaces.
```


Fiber channel

on the server side
yum install -y fcoe-utils lldpad
systemctl start lldpad

# setting up minishift

```
minishift setup-cdk
minishift config set vm-driver virtualbox
minishift config set cpus 2
minishift config set memory 12288
```

# starting minishift

```
minishift start --metrics --username rhn-gps-rspazzol --password <your_pwd> 
```

# configuring minishift VM

add support for nfs
```
echo "
  sudo setsebool -P virt_use_nfs 1
  sudo setsebool -P virt_sandbox_use_nfs 1
  sudo yum install -y nfs-utils
  " | minishift ssh
```
add time synch
```
echo " 
  sudo yum install -y chrony
  sudo systemctl start chronyd
  sudo timedatectl set-ntp yes
  sudo timedatectl set-timezone America/New_York
  " | minishift ssh  
```
start journal
```
echo " 
  sudo yum install -y rsyslog
  sudo systemctl start systemd-journald
  " | minishift ssh
```


# fabric8

gofabric8 start --vm-driver=virtualbox --minishift --memory=12288 --cpus=2
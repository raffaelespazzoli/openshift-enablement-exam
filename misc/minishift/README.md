# setting up minishift

```
minishift setup-cdk
minishift config set vm-driver kvm
minishift config set cpus 2
minishift config set memory 12288
minishift config set ocp-tag v3.9.14
minishift config set ocp-tag v3.9.27
```

minishift start --openshift-version=v3.10.14 --vm-driver=kvm \
  --cpus=2 --memory=8GB

# starting minishift

```
minishift start --skip-registration
```
MINISHIFT_ENABLE_EXPERIMENTAL=y minishift start --extra-clusterup-flags='--istio \
               --launcher \
               --launcher-catalog-git-branch=istio \
               --launcher-catalog-git-repo=https://github.com/snowdrop/launcher-booster-catalog.git \
               --launcher-openshift-user=admin \
               --launcher-openshift-password=admin \
               --launcher-github-token="" \
               --launcher-github-username=""' \
               --skip-registration

```
minishift start --metrics --username rhn-gps-rspazzol --password <your_pwd> 
```
```
minishift start --openshift-version=v3.7.0 --metrics  --extra-config="kubelet.AllowedUnsafeSysctls=kernel.core_pattern"
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
consider this optimization in ansible.cfg
```
[ssh_connection]
ssh_args = -C -o ControlMaster=auto -o ControlPersist=1800s -o GSSAPIAuthentication=no -o PreferredAuthentications=publickey
control_path = /var/run/%%h-%%r
pipelining = True
fork = 10
```
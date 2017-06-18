# build the image locally
This build requires containers with at least 12GB, the deafult is 10GB
Add `--storage-opt dm.basesize=15G` to your docker daemon config
For it to take effect you also have to run
```
docker rm `docker ps -a -q` && docker rmi -f `docker images -q`
sudo systemctl stop docker
sudo rm -rf /var/lib/docker
sudo systemctl start docker
```
download the [grid and oracle](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/database12c-linux-download-2240591.html) zip files and unzip them in a dir that we will call $ORACLE_DATA/stage/12.1.0.2

```
ls $ORACLE_DATA/stage/12.1.0.2
database  grid
``` 
to build the image run
```
docker build -t raffaelespazzoli/oracledb -v $ORACLE_DATA/stage:/stage:ro -f Dockerfile.ee .
```
notice that the `-v` option for a `docker build` command is available only in the redhat family of OSes (Fedora or RHEL).


# pushing the image to a registry

```
docker login -u ciao -p `oc whoami -t` docker-registry-default.192.168.99.100.xip.io:443
docker tag raffaelespazzoli/oracledb:latest docker-registry-default.192.168.99.100.xip.io:443/oracle-rac/oracle-rac:0.0.1
docker push docker-registry-default.192.168.99.100.xip.io:443/oracle-rac/oracle-rac:0.0.1

```      

# preparing openshift to run the image
the resulting image is about 12GB so it can be run by a default docker configuration. Again we need to change the base size ofr the file system of docker containers

Add `--storage-opt dm.basesize=15G` to your docker daemon config
For it to take effect you also have to run
```
sudo docker rm `docker ps -a -q` && sudo docker rmi -f `docker images -q`
sudo systemctl stop docker
sudo rm -rf /var/lib/docker
sudo systemctl start docker
```

If you created your cluster with an ansible file you can do the following (this will create an outage to your cluster):

```
ansible nodes -b -i hosts -m shell -a "systemctl stop atomic-openshift-node.service"
ansible nodes -b -i hosts -m shell -a 'docker stop `docker ps -q` && docker rm `docker ps -a -q` && docker rmi -f `docker images -q`'
ansible nodes -b -i hosts -m shell -a "systemctl stop docker"
ansible -vv nodes -b -i hosts -m replace -a "dest=/etc/sysconfig/docker regexp=\"OPTIONS='\" replace=\"OPTIONS=' --storage-opt dm.basesize=15G \" backup=yes"
ansible nodes -b -i hosts -m shell -a "rm -rf /var/lib/docker"
ansible nodes:!masters -b -i hosts -m shell -a "lvremove -f docker-vg/docker-pool && vgremove -f docker-vg"
ansible nodes -b -i hosts -m shell -a "systemctl start docker"
ansible nodes -b -i hosts -m shell -a "systemctl start atomic-openshift-node.service"
```

# building the image in openshift

In order to download the oracle binaries you need to login to OTN and accept the license. This setp has not been automated.
Open your browser at http://www.oracle.com/technetwork/database/enterprise-edition/downloads/database12c-linux-download-2240591.html, login in oracle, accept the license and export the cookies in a file called `cookies.txt`
In chrome you can use this [extension](https://chrome.google.com/webstore/detail/cookietxt-export/lopabhfecdfhgogdbojmaicoicjekelh) to export the cookies.
remember the exported cookies are valid for 20 minutes.

The exported cookies should look like the following:

```
# Cookies for domains related to oracle.com.
# This content may be pasted into a cookies.txt file and used by wget
# Example:  wget -x --load-cookies cookies.txt http://www.oracle.com/technetwork/database/enterprise-edition/downloads/database12c-linux-download-2240591.html
#
www.oracle.com  FALSE /technetwork/database/enterprise-edition/downloads  FALSE 0 testSessionCookie Enabled
.oracle.com TRUE  / FALSE 0 xdVisitorId 1207vAfAwRiqxHS4YGj1cL6BuPrY-jtS-4nAzaXIIMv470A1CF3
.oracle.com TRUE  / FALSE 2145916800  atgRecVisitorId 1207vAfAwRiqxHS4YGj1cL6BuPrY-jtS-4nAzaXIIMv470A1CF3
.oracle.com TRUE  / FALSE 0 atgRecSessionId O8KG8QX68dfMb-PcNt4k8aToJBNkhj3Ye2Zbq71C0GoDiy-5B-X0!293417707!-907077496
.oracle.com TRUE  / FALSE 1650384003  s_fid 1255C49F6E8840C5-37DC7BC34C5968FA
.oracle.com TRUE  / FALSE 1497377447  s_nr  1494785447773
docs.oracle.com FALSE / FALSE 0 ORA_E11882_01_NAV e48294idm140205046485520,e18951idm140205087322016,e41134idm140205094826208
docs.oracle.com FALSE / FALSE 0 ORA_B28359_01_NAV b31207idm139751918565728
community.oracle.com  FALSE / FALSE 0 jive.login.ts 1494968157860
community.oracle.com  FALSE / FALSE 0 BIGipServer~Public~community_engage_prod_pool_8080  rd2o00000000000000000000ffff89fe12a9o8080
docs.oracle.com FALSE / FALSE 0 ORA_E50529_01_NAV CWLINidm139859782340992,LADBIidm139859713601744
docs.oracle.com FALSE / FALSE 1558121675  __atuvc 17%7C20
docs.oracle.com FALSE / FALSE 1558121675  __atssc google%3B9
community.oracle.com  FALSE / FALSE 0 X-JCAPI-Token IUBuoXkq
community.oracle.com  FALSE / FALSE 0 jive.security.context mIf1Krg+UOZAlqeoJonhu///////////SwS5HjI4wM1qsbR1r8XTOGYSUWKjvL7g6RmG4NCmCBEckCD6TVfgb4Q6SxtEP++OxStDvSR7wNv/rzs1HgXJLKi4hS3fVMwD
community.oracle.com  FALSE / FALSE 0 JSESSIONID  B7212F937BA6D790F8760A8DD8CCB9B2
login.oracle.com  FALSE / FALSE 0 login-ext-prod_iper rd2o00000000000000000000ffff89fe1202o7777
www.oracle.com  FALSE / FALSE 0 JSESSIONID  ACF1fixx1C6NO3qB8LA2xcFgj8eEPhawoif0KsJS2UYUFgK2IZH8!2049917411!-63830852
.oracle.com TRUE  / FALSE 1496624666.604265 ak_bmsc 2370406CFEC89E416374E503F459EC4217C967D421550000FA9134592B971A1D~plHpg24ClfUi61NIgHsSUI59mDh1U3hrxBpUzXeqosONYvO9+9tixLzWEhJ4zwiFC/etPuk8jsW3Xbqgd0ohpHkCzGUpKhCjtjOmreHUjA02LfmkulVIecsil8xBsAXmHIkGiroaBYGxIZZt8A/iX+ziuoIRZ4y7Uv2rT/Iv3m7DIGNCwpkYSYzuEN745k6BN21zxiCQB5MRL1zq6KlqFzUw==
.oracle.com TRUE  / FALSE 1504397246.864913 ORA_WWW_MRKT  v:1~g:D3AD7338FB3FB021E0401490B1AA496A~t:NOT_FOUND~c:LP05
.oracle.com TRUE  / FALSE 1504397246.865213 ORA_WWW_PERSONALIZE v:1~i:NOT_FOUND~r:NOT_FOUND~g:LAD~l:en~cs:NOT_FOUND~cn:NOT_FOUND
.oracle.com TRUE  / FALSE 1528157246.865356 ORASSO_AUTH_HINT  v1.0~20170605080726
.oracle.com TRUE  / FALSE 1504397246.865479 ORA_UCM_INFO  3~D3AD7338FB3FB021E0401490B1AA496A~Raffaele~Spazzoli~raffaele.spazzoli@gmail.com
login.oracle.com  FALSE / TRUE  0 OAM_ID  VERSION_4~gYX8nnXHqYn+mxI9+XcYJQ==~NyChLa91+larh3kJHOnb/ED3dEh2VnMIF1nRm//PqyR5yvCCcKj1eyL726e4QsGnZyD8xmnPrSQQpsUl+/ualzdnbGJx2i+Rz7IVI5NO0jKTO/yeobPKDgFFNZCPmjd0GAz0aL3FpOz43imPMDBXBokncT6p1tUrccdCQtcPai2XjGftqh+/+1onQ2eSHqW/9fDaOH/2Zv61Z2y9Z4xa4UrLBtL3qNwAkhIF+oblsOSrzSuPOhRx1xL2wm7ppuxklBARiVfXl5b1SfsqhPTSxwWupTUh1aiO14JGLZjPkpypztFRyyAwIkOt5vF+A3nzzWGSWohLioUzMof98iHTIQ==
login.oracle.com  FALSE / FALSE 0 TS0198f255  016b044584974680287afe7bae1d48069071aabd197f90db4a5b8e97c18b74bda9400769078a01f54965ed322f17c1b4a1770561e510b4ef13aba67483dda0f4342613a60f073eb56bafeae87ec773d87e4c026a67
.oracle.com TRUE  / FALSE 0 TS01e9147f  016b044584baf04b485a31b7e5e4d13c271014320b876b2201f0aa8c9812b9ccc1310ac38e7f7c68c956ce267addffdc4fe4293023f24346c6b4491cacbd64490ece1aeed1ab6f498a484d7d87dd339db68317c8141028003192812821f107c503a83b4dc6d99b75ac09c547011e70e403b9982ef2e255c616e998be18a63be854a7ac2a51
edelivery.oracle.com  FALSE / FALSE 0 OHS-edelivery.oracle.com-443  81710027816D9E0AAC79937BDFCEC0DF7A7D8C555DA28A84B038ADDAEB8EF948842A41C03638712DA83AB678D008E19DD637DB55F0768775C92A67B572C682EAEEFE1E12513F9BF50E497B8BDBD530A72847B0936BA7677648628DD6E7FABEC4D4253CEFABF49CEC0E236037FF2559E7A2528501FF4525A2A31BEC3A03A0DB481EFCF05A1BA6530853B4DDE782832A15C23E140EBEF7338BBA230084A4A8A7914B184EB54411D5D4E8163964617488B585C6A56CB101AC9F44B66A206A695E0A887042D3662ECBBB39D27E202A868F38853C6DFAF88CDA1E2658ADDFF9A3FED531ABC5801B5A77061496A87D0EAD1A394AA960AEFDBA7A0AF1CB24B0AF7F55396843DC6A0E9201CA~
.oracle.com TRUE  / FALSE 1528157256  mmapi.store.p.0 %7B%22mmparams.d%22%3A%7B%7D%2C%22mmparams.p%22%3A%7B%22pd%22%3A%221528157256885%7C%5C%22-1720664346%7CHAAAAApVAgDiy5Zq1g4AARAAAUIU41IMCgDpem7fpqvUSOz0i5nWo9RIAAAAAP%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FAAZEaXJlY3QB3g4JAAEAAAAAAAAA%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2F%2FAAAAAAAAAAFF%5C%22%22%2C%22srv%22%3A%221528157256904%7C%5C%22nycvwcgus04%5C%22%22%7D%7D
.oracle.com TRUE  / FALSE 0 mmapi.store.s.0 %7B%22mmparams.d%22%3A%7B%7D%2C%22mmparams.p%22%3A%7B%7D%7D
.oracle.com TRUE  / FALSE 0 s_cc  true
.oracle.com TRUE  / FALSE 1496623059  oraclelicense accept-database_111060_linx8664-cookie
.oracle.com TRUE  / FALSE 1496623059  gpw_e24 http%3A%2F%2Fwww.oracle.com%2Ftechnetwork%2Fdatabase%2Fenterprise-edition%2Fdownloads%2Fdatabase12c-linux-download-2240591.html
.oracle.com TRUE  / FALSE 0 s_sq  oracleotnlive%2Coracleglobal%3D%2526pid%253Dotn%25253Aen-us%25253A%25252Fdatabase%25252Fenterprise-edition%25252Fdownloads%25252Fdatabase12c-linux-download-2240591.html%2526pidt%253D1%2526oid%253Dfunctiononclick(event)%25257BacceptAgreement(window.self)%25253B%25257D%2526oidt%253D2%2526ot%253DRADIO
```
Once you have the cookie file proceed with downloading the binaries.

```
oc new-project oracle-rac
oc new-build https://github.com/raffaelespazzoli/openshift-enablement-exam --name=download-binaries --strategy=docker --context-dir=misc/oracle-rac -D "FROM registry.access.redhat.com/rhel7-atomic:latest"
oc patch bc/download-binaries --patch '{"spec" : { "strategy" : { "dockerStrategy" : { "dockerfilePath" : "Dockerfile.download.installBinaries" }}, "source" : { "dockerfile" : ""}}}'
oc start-build download-binaries -F
oc secrets new cookies cookies.txt=cookies.txt
oc create sa nginx
oc adm policy add-scc-to-user anyuid -z nginx
oc apply -f https://raw.githubusercontent.com/raffaelespazzoli/openshift-enablement-exam/master/misc/oracle-rac/openshift/downloadBinaries.yaml

```
execute the first step of the build

```
oc new-build https://github.com/raffaelespazzoli/openshift-enablement-exam --name=oracle-rac-base-1 --build-secret="cookies:./cookies" --strategy=docker --context-dir=misc/oracle-rac -D "FROM oraclelinux:7-slim" -e DOWNLOAD-URL=binaries-http-server.oracle-rac.svc.cluster.local:8080
oc patch bc/oracle-rac-base-1 --patch '{"spec" : { "strategy" : { "dockerStrategy" : { "dockerfilePath" : "Dockerfile.openshift.step1" }}, "source" : { "dockerfile" : ""}}}'
oc start-build oracle-rac-base-1 -F 
```
after the build completes, create another delete the old cookie.txt file and create a new one with fresh cookie to support the second step of the build
```
oc delete secret cookies
oc secrets new cookies cookies.txt=cookies.txt
oc new-build https://github.com/raffaelespazzoli/openshift-enablement-exam --name=oracle-rac-base-2 --build-secret="cookies:./cookies" --strategy=docker --context-dir=misc/oracle-rac -D "FROM oracle-rac-base-1:latest"
oc patch bc/oracle-rac-base-2 --patch '{"spec" : { "strategy" : { "dockerStrategy" : { "dockerfilePath" : "Dockerfile.openshift.step2" }}, "source" : { "dockerfile" : ""}}}'
oc start-build oracle-rac-base-2 -F  
```


# notes
https://github.com/Seth-Miller/12c-rac-docker
https://github.com/s4ragent/rac_on_xx


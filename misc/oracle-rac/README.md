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

open your browser at http://www.oracle.com/technetwork/database/enterprise-edition/downloads/database12c-linux-download-2240591.html accept the license and export the cookies in a file called cookies.txt

```
oc new-project oracle-rac
oc secrets new cookies cookies.txt=cookies.txt
oc new-build -n oracle-rac-base --build-secret “cookies:/root" -D Dockerfile.ee.openshift https://github.com/raffaelespazzoli/openshift-enablement-exam/tree/master/misc/oracle-rac
```

# notes
https://github.com/Seth-Miller/12c-rac-docker
https://github.com/s4ragent/rac_on_xx




-----------


function disableAnchor(obj, disable){
  if(disable){
  var href = obj.getAttribute("href");
  if(href && href != "" && href != null){
     obj.setAttribute('href_bak', href);
  }
  // obj.setAttribute('href', 'http://www.oracle.com/technetwork/licenses/sorry-150381.html');
  obj.removeAttribute('href');
  obj.setAttribute('class', 'boldbodylink');
  } else {
  obj.setAttribute('href', obj.getAttribute('href_bak'));
  obj.setAttribute('class', 'boldbodylink');
  }
}

function disableAnchorByName(anchorname, disable){
//  var use_gebi=false;
  var o=null;
  // if (document.getElementById) { use_gebi=true; }
  // Logic to find position
  // if (use_gebi) {
  //  o=document.getElementById(anchorname);
  // } else {
  for (var i=0; i<document.anchors.length; i++) {
    if (document.anchors[i].name==anchorname) { o=document.anchors[i]; break; }
  }
  disableAnchor(o, disable);
}

function disableAnchorByName(doc, anchorname, disable, enabledHref, onclickFtn){
  var use_gebi=false;
  var o=null;
  for (var i=0; i<doc.anchors.length; i++) {
    if (doc.anchors[i].name==anchorname) { o=doc.anchors[i]; break; }
  }
  disableAnchor(o, disable, enabledHref, onclickFtn);
}

function disableAnchor( obj, disable, enabledHref, onclickFtn ){
  if(disable){
  obj.onclick = onclickFtn;
  // obj.setAttribute('onclick', disabledHref );
  // obj.removeAttribute('href');
  // obj.setAttribute('href', onclickFtn );
  obj.setAttribute('class', 'boldbodylink');
  } else {
  obj.setAttribute('href', enabledHref );
  obj.onclick = null;
  obj.setAttribute('class', 'boldbodylink');
  }
}

function disableDownloadAnchors(doc, disabled){

  // NOTE: These vars are being passed to the methods below, so the var name  should
  //       match the parameter passed to the method. Customize var names for download(s) involved
  var file1 = 'http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_database_1of2.zip';
  var file2 = 'http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_database_2of2.zip';
  var file3 = 'http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_grid_1of2.zip'; 
  var file4 = 'http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_grid_2of2.zip';
  var file5 = 'http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_gsm.zip';
  var file6 = 'http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_gateways.zip';
  var file7 = 'http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_examples.zip';
  var file8 = 'http://download.oracle.com/otn/linux/oracle12c/121020/linuxamd64_12102_client.zip';
  var file9 = 'http://download.oracle.com/otn/linux/oracle12c/121020/linux_12102_client32.zip';
  var file10 = 'http://download.oracle.com/otn/linux/middleware/11g/111170/ofm_webtier_linux_11.1.1.7.0_64_disk1_1of1.zip';
  

  var agreementPrompt = new Function( "alert('Sorry, you must accept the License Agreement before downloading.');" );
  disableAnchorByName(doc, 'file1', disabled, file1, agreementPrompt);
  disableAnchorByName(doc, 'file2', disabled, file2, agreementPrompt);  
  disableAnchorByName(doc, 'file3', disabled, file3, agreementPrompt);
  disableAnchorByName(doc, 'file4', disabled, file4, agreementPrompt);
  disableAnchorByName(doc, 'file5', disabled, file5, agreementPrompt);
  disableAnchorByName(doc, 'file6', disabled, file6, agreementPrompt);
  disableAnchorByName(doc, 'file7', disabled, file7, agreementPrompt);
  disableAnchorByName(doc, 'file8', disabled, file8, agreementPrompt);
  disableAnchorByName(doc, 'file9', disabled, file9, agreementPrompt);
  disableAnchorByName(doc, 'file10', disabled, file10, agreementPrompt);
      
}

function youMustAgreePrompt(){
  alert('Sorry, you must accept the License Agreement before downloading.');
}

function acceptAgreement(windowRef){
  var doc = windowRef.document;
  disableDownloadAnchors(doc, false);
  hideAgreementDiv(doc);
  writeSessionCookie( 'oraclelicense', 'accept-database_111060_linx8664-cookie' );
}

function declineAgreement(windowRef){
  var doc = windowRef.document;
  disableDownloadAnchors(doc, true);
  writeSessionCookie( 'oraclelicense', 'decline' );
  // forward();
}

function showAgreement(){
  window.open('/technetwork/licenses/standard-license-152015.html','LicenseAgreement','status=1,scrollbars=1,width=500,height=400,top=150,left=400');
}

function forward(){
  location.href="http://www.oracle.com/technetwork/licenses/sorry-150381.html";
}

function hideAgreementDiv(doc) {
  if (doc.getElementById) { // DOM3 = IE5, NS6
    doc.getElementById('agreementDiv').style.visibility = 'hidden';
    doc.getElementById('thankYouDiv').style.visibility = 'visible';
  } else {
    if (doc.layers) { // Netscape 4
      doc.agreementDiv.visibility = 'hidden';
      doc.thankYouDiv.visibility = 'visible';
    } else { // IE 4
      doc.all.agreementDiv.style.visibility = 'hidden';
      doc.all.thankYouDiv.style.visibility = 'visible';
    }
  }
}

function agreementToSign(){
  alert('Ooooo ... you are about to sign some really big agreement!');
}

function resetAgreementForm(){
  //alert('here 1');
  var cookie = getCookieValue('oraclelicense');
  var myRadios = document.agreementForm['agreement'];
  
  if(cookie == null){
    document.agreementForm.reset();
  } else if(cookie == 'accept-database_111060_linx8664-cookie') {
    myRadios[0].checked = 'true';
    acceptAgreement();
  } else if(cookie == 'decline'){
    myRadios[1].checked = 'true';
  }
}


----------
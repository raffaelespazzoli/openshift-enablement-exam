## install sonarqube
```
oc new-project sonarqube
oc new-app --template postgresql-persistent --param=POSTGRESQL_USER=sonar  --param=POSTGRESQL_PASSWORD=sonar --param=POSTGRESQL_DATABASE=sonar -l app=sonarqube
cat << EOF  | oc create -f - -n sonarqube
---
apiVersion: "v1"
kind: "PersistentVolumeClaim"
metadata:
  name: "sonarqube-extensions"
spec:
  accessModes:
    - "ReadWriteMany"
  resources:
    requests:
      storage: "1Gi"
---
apiVersion: "v1"
kind: "PersistentVolumeClaim"
metadata:
  name: "sonarqube-data"
spec:
  accessModes:
    - "ReadWriteMany"
  resources:
    requests:
      storage: "1Gi"
EOF
oc new-app sonarqube SONARQUBE_JDBC_URL=jdbc:postgresql://postgresql:5432/sonar -l app=sonarqube -n sonarqube
oc volume dc/sonarqube --add -m /opt/sonarqube/data --claim-name=sonarqube-data --overwrite=true -n sonarqube
oc volume dc/sonarqube --add -m /opt/sonarqube/extensions --claim-name=sonarqube-extensions --overwrite=true -n sonarqube
oc expose service sonarqube -n sonarqube
```

#install nexus
oc new-project nexus
oc new-app fabric8/nexus -n nexus
cat << EOF  | oc create -f - -n nexus
---
apiVersion: "v1"
kind: "PersistentVolumeClaim"
metadata:
  name: "sonatype-work"
spec:
  accessModes:
    - "ReadWriteMany"
  resources:
    requests:
      storage: "1Gi"
EOF
oc volume dc/nexus --add -m /sonatype-work --claim-name=sonatype-work --overwrite=true -n nexus
# sometimes the nexus image is not scanned correclty and the exposed port is not found. In this case add 8081 to the container definition and create the service
cat << EOF | oc create -f -
apiVersion: v1
kind: Service
metadata:
  name: nexus      
spec:
  selector:                  
    app: nexus   
  ports:
  - port: 8081               
    protocol: TCP
EOF
oc expose svc nexus -n nexus

#install clair
oc new-project clair
wget -qO- https://raw.githubusercontent.com/raffaelespazzoli/aloha/master/src/main/openshift/clair-config.yaml | oc secrets new clairsecret config.yaml=-  -n clair

oc create -f https://raw.githubusercontent.com/raffaelespazzoli/aloha/master/src/main/openshift/clair-openshift.yaml -n clair
# oc expose service clairsvc --port=6060
# clair will take several minutes to download the vulnerability definitions


# Install jenkins
# make sure you have an available pv, jenkins will grab it.
Create pre-configured jenkins image
oc project openshift
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/jenkins/master/custom-jenkins.build.yaml
oc start-build custom-jenkins-build --follow

oc new-project ci
oc new-app --template=jenkins-persistent --param=JENKINS_PASSWORD=password -n ci

# Make sure you install openshift pipeline jenkins plugin
# Make sure you install the Pipeline Maven Integration Plugin

#install hygieia
oc new-project hygieia
oc create -f https://raw.githubusercontent.com/raffaelespazzoli/aloha/master/src/main/openshift/hygieia-mongo.yaml -n hygieia
oc process -f https://raw.githubusercontent.com/raffaelespazzoli/aloha/master/src/main/openshift/hygieia.yaml | oc create -f -  -n hygieia
oc expose service hygieia-ui -n hygieia

# Application creation
oc new-project helloworld-msa-dev
oc new-project helloworld-msa-qa
oc new-project helloworld-msa

# Give jenkins permission to see and edit helloworld-msa-dev
oc policy add-role-to-user view system:serviceaccount:ci:jenkins -n helloworld-msa-dev
oc policy add-role-to-user edit system:serviceaccount:ci:jenkins -n helloworld-msa-dev



# In jenkins go to the openshift jenkins plugin and set the synched namespace to be helloworld-msa-dev
# make sure you have maven installation named M3
# make sure you have a jdk installation named jdk8
# make sure that the jenkins sync plugin is monitoring helloworld-msa-dev, because of a bug only one project is supported at this time

# create pipeline build config
wget -qO- https://raw.githubusercontent.com/raffaelespazzoli/aloha/master/src/main/openshift/jenkins/aloha-bc.yaml | oc create -f - -n helloworld-msa-dev

# start pipeline bc
oc start-build aloha-pipeline -n helloworld-msa-dev


TODO:
Install hygieia
Connect hygieia connectors
Build image
Scan image with hyperclair
Create dc if not there
Start deploy
Tag image for qa
Find load test tool
Create load test tool
Creata dc if not there
Create hpa if no there
Deploy in qa
Lanuch load test
Find chaos monkey tool
Install chaos moneky tool
Lanuch chaos monkey tool
Tag for production
Approval step
Create dc for production if not there
Create hpa if not there
Deploy in prod

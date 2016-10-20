## preparation

you need a working cluster.
you need 10 pvs or dynamic pv enabled

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
    - "ReadWriteOnce"
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
    - "ReadWriteOnce"
  resources:
    requests:
      storage: "1Gi"
EOF
oc new-app https://github.com/OpenShiftDemos/sonarqube-openshift-docker --strategy=docker --name=sonarqube -e SONARQUBE_JDBC_USERNAME=sonar,SONARQUBE_JDBC_PASSWORD=sonar,SONARQUBE_JDBC_URL=jdbc:postgresql://postgresql:5432/sonar -l app=sonarqube -n sonarqube
oc volume dc/sonarqube --add -m /opt/sonarqube/data --claim-name=sonarqube-data -n sonarqube
oc volume dc/sonarqube --add -m /opt/sonarqube/extensions --claim-name=sonarqube-extensions -n sonarqube
oc expose service sonarqube -n sonarqube
```

#install nexus

```
oc new-project nexus
cat << EOF  | oc create -f - -n nexus
apiVersion: "v1"
kind: "PersistentVolumeClaim"
metadata:
  name: "sonatype-work"
spec:
  accessModes:
    - "ReadWriteOnce"
  resources:
    requests:
      storage: "1Gi"
EOF
oc new-app https://github.com/OpenShiftDemos/nexus-openshift-docker --strategy=docker --name=nexus -l app=nexus -n nexus

oc volume dc/nexus --add -m /sonatype-work --claim-name=sonatype-work --overwrite=true -n nexus
oc expose svc nexus -n nexus
```

#install clair
```
oc new-project clair
cat << EOF > clair-config.yaml
clair:
  database:
    source: postgres://clair:clair@postgresql:5432/clair?sslmode=disable
    cacheSize: 16384
  api:
    port: 6060
    healthport: 6061
    timeout: 900s
    paginationKey:
    servername:
    cafile:
    keyfile:
    certfile:

  updater:
    interval: 2h

  notifier:
    attempts: 3
    renotifyInterval: 2h
    http:
      endpoint:
      servername:
      cafile:
      keyfile:
      certfile:
EOF
oc secrets new clairsecret config.yaml=clair-config.yaml  -n clair
rm clair-config.yaml

oc new-app --template postgresql-persistent --param=POSTGRESQL_USER=clair  --param=POSTGRESQL_PASSWORD=clair --param=POSTGRESQL_DATABASE=clair -n clair

cat << EOF | oc create -f -
apiVersion: v1
kind: Service
metadata:
  name: clairsvc
  labels:
    app: clair
spec:
  ports:
  - port: 6060
    protocol: TCP
    name: api
  - port: 6061
    protocol: TCP
    name: healtz
  selector:
    app: clair
---
apiVersion: v1
kind: DeploymentConfig
metadata:
  name: clair
spec:
  replicas: 1
  triggers:
  - type: ConfigChange
  strategy:
    type: Rolling
  template:
    metadata:
      labels:
        app: clair
    spec:
      volumes:
      - name: secret-volume
        secret:
          secretName: clairsecret
      containers:
      - name: clair
        image: quay.io/coreos/clair
        args:
          - "-config"
          - "/config/config.yaml"
        ports:
        - containerPort: 6060
        - containerPort: 6061
        volumeMounts:
        - mountPath: /config
          name: secret-volume
EOF
```

clair will take several minutes to download the vulnerability definitions


# Install jenkins
```
Create pre-configured jenkins image
oc project openshift
cat << EOF | oc create -f -
apiVersion: v1
kind: BuildConfig
metadata:
  name: custom-jenkins-build
spec:
  source:
    git:
      uri: https://github.com/redhat-helloworld-msa/jenkins
    type: Git
  strategy:
    sourceStrategy:
      from:
        kind: DockerImage
        name: registry.access.redhat.com/openshift3/jenkins-1-rhel7
    type: Source
  output:
    to:
      kind: ImageStreamTag
      name: jenkins:latest
EOF 
oc start-build custom-jenkins-build --follow

oc new-project ci
oc new-app --template=jenkins-persistent --param=JENKINS_PASSWORD=password -n ci
```
Make sure you install openshift pipeline jenkins plugin
Make sure you install the Pipeline Maven Integration Plugin

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

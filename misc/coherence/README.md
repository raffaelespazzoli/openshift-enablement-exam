# Coherence Install steps

[Download Server JRE 8](http://www.oracle.com/technetwork/java/javase/downloads/server-jre8-downloads-2133154.html) `.tar.gz` file and drop it inside folder `oraclejava`

[Download coherence standalone 12.2.1.2.0](http://www.oracle.com/technetwork/middleware/coherence/downloads/index.html) and drop it in the folder `coherence`

```
oc new-project coherence
oc adm policy add-scc-to-user anyuid -z default
cd oraclejava
oc new-build --strategy=docker --name=oraclejre --binary=true --docker-image=oraclelinux:7-slim
oc start-build oraclejre --from-dir=. -F
oc tag oraclejre:latest oraclejre:8


cd ../coherence
oc new-build --strategy=docker --name=coherence --binary=true --image-stream=oraclejre:8
oc start-build coherence --from-dir=. -F
oc tag coherence:latest coherence:12.2.1.2.0-standalone

cd ..

oc process -f coherence-template.yaml | oc apply -f -
```
to scale to 5 instance:
```
oc scale statefulset/coherence --replicas=5
```
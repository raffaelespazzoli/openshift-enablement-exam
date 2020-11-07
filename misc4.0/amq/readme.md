# AMQ

## Prerequisites

Install a recent version of cert-manager

```shell
oc new-project cert-manager
oc apply --validate=false -f https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.yaml
```

## Install AMQ and Interconnect Operator

```shell
export project=amq
oc new-project ${project}
envsubst < ./operator.yaml | oc apply -f - -n ${project}
```

## Helper Operators (optional)

```shell
oc apply -f https://raw.githubusercontent.com/redhat-cop/resource-locker-operator/master/deploy/olm-deploy/subscription.yaml -n ${project}
helm repo add stakater https://stakater.github.io/stakater-charts
helm repo update
export uid=$(oc get project ${project} -o jsonpath='{.metadata.annotations.openshift\.io/sa\.scc\.uid-range}'|sed 's/\/.*//')
helm upgrade -i -n ${project} reloader stakater/reloader --set reloader.deployment.securityContext.runAsUser=${uid}
```

Resource locker operator automates the injection of the injection of keystore and truststore in the secrets
Reloader automates the reboot of pods when certificates are renewed.

## Install AMQ Broker

### Prepare certificates

```shell
export base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
envsubst < ./certs.yaml | oc apply -f - -n ${project}

# if you installed resource-locker-operator run this
oc adm policy add-role-to-user edit -z default -n ${project}
envsubst < ./cert-patches.yaml | oc apply -f - -n ${project}


# if you didn't install resource-locker-operator run this (and re-run it every time certificates are renewed)
oc get secret amq-amqp-tls-secret -o jsonpath='{.data.keystore\.jks}' -n ${project} | base64 -d > /tmp/broker.ks
oc get secret amq-amqp-tls-secret -o jsonpath='{.data.truststore\.jks}' -n ${project} | base64 -d > /tmp/client.ts
oc set data --from-file=/tmp/broker.ks --from-file=/tmp/client.ts -n ${project}
oc get secret amq-console-secret -o jsonpath='{.data.keystore\.jks}' -n ${project} | base64 -d > /tmp/broker.ks
oc get secret amq-console-secret -o jsonpath='{.data.truststore\.jks}' -n ${project} | base64 -d > /tmp/client.ts
oc set data --from-file=/tmp/broker.ks --from-file=/tmp/client.ts -n ${project}
```



### Install AMQ Broker and Interconnect

```shell
oc apply -f ./amq.yaml -n ${project}
```

### Certificate renewal

```shell
# if you installed skater/reloader, run:
oc annotate statefulset amq-ss reloader.stakater.com/auto="true" -n ${project}

# if you didn't install skater/reloader, run this every time the certificates are renewed
oc rollout restart statefulset amq-ss -n ${project}
```

## Run a client app

The app can be found here: https://github.com/j-michels/amq-test

```shell
oc new-app registry.redhat.io/ubi8/openjdk-11~https://github.com/raffaelespazzoli/amq-test --name springboot-amq -n ${project} -l app=amq-test
envsubst < application-properties.yaml | oc apply -f - -n ${project}
oc set volume deployment/springboot-amq --add --configmap-name=application-properties --mount-path=/config --name=config -t configmap -n ${project}
oc set volume deployment/springboot-amq --add --secret-name=amq-amqp-tls-secret --mount-path=/certs --name=certs -t secret -n ${project}
oc set env deployment/springboot-amq SPRING_CONFIG_LOCATION=/config/application-properties.yaml -n ${project}
oc set env deployment/springboot-amq SPRING_CONFIG_LOCATION=/config/application-properties.yaml -n ${project}
oc expose service springboot-amq --port 8080-tcp -n ${project}
curl -X POST http://springboot-amq-${project}.apps.${base_domain}/api/post/myqueue -H 'Content-Type: application/json' -d ciao
```

## Install interconnect

Interconnect provides the ability to create broker topology-unaware clients and sets you up for multi-cluster deployment of the brokers.

### Deploy interconnect operator

```shell
oc apply -f ./interconnect-operator.yaml
```

### Deploy certificates

```shell
export base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
envsubst < ./interconnect-certs.yaml | oc apply -f - -n ${project}
```

### Deploy router-mesh

```shell
oc apply -f ./interconnect.yaml -n ${project}
```

### Interconnect certificate renewal

```shell
# if you installed skater/reloader, run:
oc annotate deployment router-mesh reloader.stakater.com/auto="true" -n ${project}

# if you didn't install skater/reloader, run this every time the certificates are renewed
oc rollout restart deployment router-mesh -n ${project}
```

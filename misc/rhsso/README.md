# Install RHSSO

1. update templates if necessary

## create the project

```
export project=rhsso
export cluster_domain=apps.env1.casl.raffa.com
oc new-project $project
```

## generate secrets
```
export pleaseHackMePasswd=ciaociao
export WORK_DIR=`pwd`/ssl_ca
./ssl-ca.sh
cd $WORKDIR
openssl genrsa -out private/acme-ca.key -des3 -passout pass:$pleaseHackMePasswd 2048
openssl req -new -x509 -key private/acme-ca.key -days 365 -out acme-ca.crt -subj "/CN=ACME Certification Authority" -passin pass:$pleaseHackMePasswd
keytool -genkeypair -keyalg RSA -keysize 2048 \
          -alias sso-ssl-key \
          -keystore sso-ssl.jks \
          -storepass $pleaseHackMePasswd \
          -keypass $pleaseHackMePasswd \
          -dname "CN=secure-sso-$project.$cluster_domain,OU=Oblivion,O=$cluster_domain,L=Neverland,S=OH,C=US" 
keytool -certreq -keyalg rsa -alias sso-ssl-key -keystore sso-ssl.jks -storepass $pleaseHackMePasswd -file sso-ssl.csr
openssl ca -config ca.cnf -out sso-ssl.crt -passin pass:$pleaseHackMePasswd -batch -infiles sso-ssl.csr
keytool -import -file acme-ca.crt -alias acme.ca -keystore sso-ssl.jks -storepass $pleaseHackMePasswd
keytool -import -file sso-ssl.crt -alias sso-ssl-key -keystore sso-ssl.jks -storepass $pleaseHackMePasswd
keytool -import -file acme-ca.crt -alias xpaas.ca -keystore truststore.jks -storepass $pleaseHackMePasswd
keytool -genseckey -alias jgroups -storetype JCEKS -keystore jgroups.jceks -storepass $pleaseHackMePasswd -keypass $pleaseHackMePasswd  
oc create serviceaccount sso-service-account
oc policy add-role-to-user view -z sso-service-account
oc create secret generic sso-app-secret \
            --from-file=./sso-ssl.jks \
            --from-file=./jgroups.jceks \
            --from-file=./truststore.jks
oc secret add sa/sso-service-account secret/sso-app-secret 
```
            
## deploy rhsso
```
oc new-app --template=sso71-mysql-persistent \
     -p HTTPS_KEYSTORE=sso-ssl.jks \
     -p HTTPS_PASSWORD=$pleaseHackMePasswd \
     -p JGROUPS_ENCRYPT_PASSWORD=$pleaseHackMePasswd \
     -p SSO_TRUSTSTORE_PASSWORD=$pleaseHackMePasswd \
     -p SSO_ADMIN_USERNAME=admin \
     -p SSO_ADMIN_PASSWORD=admin            
```                

# configuring openshift to authenticate via RHSSO


follow https://access.redhat.com/documentation/en-us/red_hat_jboss_middleware_for_openshift/3/html-single/red_hat_jboss_sso_for_openshift/#Example-Deploying-SSO



deploying sharded router
answer egress
reorganize how full is my cluster
- add cluster committment level
- add break down in two pieces
- add considerations on not limiting cpu
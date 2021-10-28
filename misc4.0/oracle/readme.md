oc apply -f https://github.com/jetstack/cert-manager/releases/download/v1.6.0/cert-manager.yaml
oc apply -f https://raw.githubusercontent.com/oracle/oracle-database-operator/main/oracle-database-operator.yaml

oc create ns shns

mkdir /tmp/.secrets/

# Generate a random openssl key
openssl rand -hex -out /tmp/.secrets/pwd.key 64

# Use a password you want and add it to a text file
echo ORacle_21c > /tmp/.secrets/common_os_pwdfile

# Encrypt the file with the password with the random openssl key generated above
openssl enc -aes-256-cbc -md md5 -salt -in /tmp/.secrets/common_os_pwdfile -out /tmp/.secrets/common_os_pwdfile.enc -pass file:/tmp/.secrets/pwd.key

# Remove the password text file
rm -f /tmp/.secrets/common_os_pwdfile

# Create the Kubernetes secret in namespace "shns"
kubectl create secret generic db-user-pass --from-file=/tmp/.secrets/common_os_pwdfile.enc --from-file=/tmp/.secrets/pwd.key -n shns

# Check the secret details 
kubectl get secret -n shns

# got o oracle container registry and accepte the license
# login to oracle container registry 

docker login container-registry.oracle.com/database/enterprise

# create a pull secret

oc create secret docker-registry oracle-container-registry --from-file=.dockerconfigjson=${XDG_RUNTIME_DIR}/containers/auth.json -n shns
oc secrets link default oracle-container-registry --for=pull -n shns

# the token created with a docker lofing is short lived.
oc delete secret ocr-reg-cred -n shns
oc create secret docker-registry ocr-reg-cred --from-file=.dockerconfigjson=${XDG_RUNTIME_DIR}/containers/auth.json -n shns


oc adm policy add-scc-to-user privileged -z default -n shns
oc apply -f ./sharded-deployment.yaml -n shns
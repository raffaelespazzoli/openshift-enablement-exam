
```shell
git clone https://github.com/backstage/backstage.git
cd backstage/contrib/chart/backstage
helm dependency update
cd ../../../..
export cluster_base_domain=$(oc get dns cluster -o jsonpath='{.spec.baseDomain}')
export PAT=$(cat ./pat.txt)
envsubst < ./values.yaml > /tmp/values.yaml
export POSTGRESQL_PASSWORD=$(kubectl get secret --namespace backstage backstage-postgresql -o jsonpath="{.data.postgresql-password}" | base64 --decode)
helm upgrade backstage chart/backstage -n backstage --create-namespace -i -f /tmp/values.yaml --set global.postgresql.postgresqlPassword=$POSTGRESQL_PASSWORD
oc adm policy add-scc-to-user anyuid -z default -n backstage
```
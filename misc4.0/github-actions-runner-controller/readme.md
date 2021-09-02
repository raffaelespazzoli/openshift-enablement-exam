# GitHub Actions Runner Controller

https://github.com/actions-runner-controller/actions-runner-controller

## Deploy

```shell
export APP_ID=133069
export INSTALLATION_ID=18955997
export PRIVATE_KEY_FILE_PATH=./raffa-actions-runner-controller.2021-08-19.private-key.pem
oc create secret generic controller-manager \
    -n actions-runner-system \
    --from-literal=github_app_id=${APP_ID} \
    --from-literal=github_app_installation_id=${INSTALLATION_ID} \
    --from-file=github_app_private_key=${PRIVATE_KEY_FILE_PATH}
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm upgrade --install --namespace actions-runner-system --create-namespace --wait actions-runner-controller actions-runner-controller/actions-runner-controller --set githubWebhookServer.enabled=true --set githubWebhookServer.service.type=ClusterIP --set githubWebhookServer.secret.create=true
oc expose --service actions-runner-controller-github-webhook-server -n actions-runner-system
```

## Test Ephemeral Runners

```shell
oc new-project test-ephemeral-runners
oc apply -f ./runner-deployment.yaml -n test-ephemeral-runners
```
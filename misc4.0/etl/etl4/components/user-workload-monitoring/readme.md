# Troubleshooting user-workload prometheus

run:

```sh
oc port-forward pod/prometheus-user-workload-0 -n openshift-user-workload-monitoring 9090:9090
http://localhost:9090
```
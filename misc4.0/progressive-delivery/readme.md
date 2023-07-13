# Prorgessive delivery

Some experiment with progressive delivery. All experiments involve the booking app and the rollout of the `reviews` service (which had three revisons in the original bookinfo demo).

[Experiment #1](./experiment-one/): 
- Traffic Management with [Istio Subset-level splitting](https://argo-rollouts.readthedocs.io/en/stable/features/traffic-management/istio/#subset-level-traffic-splitting).
- Analysis with [Prometheus Analysis](https://argo-rollouts.readthedocs.io/en/stable/analysis/prometheus/)
- Metrics from Service Mesh prometheus

[Experiment #2](./experiment-two/):
- Traffic Management with [Istio Host-level splitting](https://argo-rollouts.readthedocs.io/en/stable/features/traffic-management/istio/#host-level-traffic-splitting).
- Analysis with [Prometheus Analysis](https://argo-rollouts.readthedocs.io/en/stable/analysis/prometheus/)
- Metrics from User-workload prometheus

[Experiment #3](./experiment-three/):
- Traffic Management with Routes.
- Analysis with [Prometheus Analysis](https://argo-rollouts.readthedocs.io/en/stable/analysis/prometheus/)
- Metrics from OCP Cluster prometheus

[Experiment #4](./experiment-four/):
- Traffic Management with Gateway API.
- Analysis with [Prometheus Analysis](https://argo-rollouts.readthedocs.io/en/stable/analysis/prometheus/)
- Metrics from OCP Cluster prometheus
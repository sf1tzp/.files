kube_pod_info{created_by_name="postgres-postgresql"}

Load time: 29ms   Result series: 1
kube_pod_info{created_by_kind="StatefulSet", created_by_name="postgres-postgresql", host_ip="10.0.0.6", host_network="false", instance="k8s-cluster", job="kube_state_metrics", namespace="postgres", node="zenbook", pod="postgres-postgresql-0", pod_ip="10.42.0.106", uid="adf8401a-c606-400f-8ea5-546eb87178fd"}	1

---

kube_pod_container_resource_limits{pod="postgres-postgresql-0"}

Load time: 60ms   Result series: 4
kube_pod_container_resource_limits{container="postgresql", instance="k8s-cluster", job="kube_state_metrics", namespace="postgres", node="zenbook", pod="postgres-postgresql-0", resource="memory", uid="adf8401a-c606-400f-8ea5-546eb87178fd", unit="byte"}	536870912
kube_pod_container_resource_limits{container="metrics", instance="k8s-cluster", job="kube_state_metrics", namespace="postgres", node="zenbook", pod="postgres-postgresql-0", resource="cpu", uid="adf8401a-c606-400f-8ea5-546eb87178fd", unit="core"}	0.15
kube_pod_container_resource_limits{container="metrics", instance="k8s-cluster", job="kube_state_metrics", namespace="postgres", node="zenbook", pod="postgres-postgresql-0", resource="ephemeral_storage", uid="adf8401a-c606-400f-8ea5-546eb87178fd", unit="byte"}	2147483648
kube_pod_container_resource_limits{container="metrics", instance="k8s-cluster", job="kube_state_metrics", namespace="postgres", node="zenbook", pod="postgres-postgresql-0", resource="memory", uid="adf8401a-c606-400f-8ea5-546eb87178fd", unit="byte"}	201326592

---

container_cpu_usage_seconds_total{pod="postgres-postgresql-0"}

Load time: 21ms   Result series: 4
container_cpu_usage_seconds_total{cpu="total", id="/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-podadf8401a_c606_400f_8ea5_546eb87178fd.slice", instance="k8s-control", job="kubelet_cadvisor", namespace="postgres", pod="postgres-postgresql-0"}	14.743096
container_cpu_usage_seconds_total{cpu="total", id="/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-podadf8401a_c606_400f_8ea5_546eb87178fd.slice/cri-containerd-fb15ccf5fa3e689b8f9719f56db2a8b51c01157eb7e9c9560e25ca6458a9f1d2.scope", image="docker.io/rancher/mirrored-pause:3.6", instance="k8s-control", job="kubelet_cadvisor", name="fb15ccf5fa3e689b8f9719f56db2a8b51c01157eb7e9c9560e25ca6458a9f1d2", namespace="postgres", pod="postgres-postgresql-0"}	0.030253
container_cpu_usage_seconds_total{container="metrics", cpu="total", id="/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-podadf8401a_c606_400f_8ea5_546eb87178fd.slice/cri-containerd-af9bcd4fd3c4883b6b9223ca58c51086269bef52f7b4c1a73894d895b769d0f9.scope", image="registry-1.docker.io/bitnami/postgres-exporter:latest", instance="k8s-control", job="kubelet_cadvisor", name="af9bcd4fd3c4883b6b9223ca58c51086269bef52f7b4c1a73894d895b769d0f9", namespace="postgres", pod="postgres-postgresql-0"}	0.219507
container_cpu_usage_seconds_total{container="postgresql", cpu="total", id="/kubepods.slice/kubepods-burstable.slice/kubepods-burstable-podadf8401a_c606_400f_8ea5_546eb87178fd.slice/cri-containerd-27e337bc30c2bc6170fdd5d1d214d613c23f3a31652a3275c45e4755e3840fe8.scope", image="registry-1.docker.io/bitnami/postgresql:latest", instance="k8s-control", job="kubelet_cadvisor", name="27e337bc30c2bc6170fdd5d1d214d613c23f3a31652a3275c45e4755e3840fe8", namespace="postgres", pod="postgres-postgresql-0"}	14.56312

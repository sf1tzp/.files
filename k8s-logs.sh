#!/bin/bash

: "${LOG_DIR:="$HOME/logs/"}"
: "${ARCHIVE:="false"}"
: "${CLEANUP_LOOSE_FILES:="false"}"

function gather_cluster_data() {
  log_dir="$LOG_DIR/$(date '+%Y-%m-%d')/$(date '+%H%M')"
  mkdir -p "$log_dir"

  # We'll make a lot of calls to the API server to get this data.
  # We'll background these calls and then wait on thier PID to speed
  # this process up.
  pid_array=()

  describe_nodes &
  pid_array+=($!)

  namespaces=$(kubectl get namespaces -o go-template --template="{{ range .items }}{{ .metadata.name }} {{ end }}")
  for namespace in $namespaces; do
    container_logs &
    pid_array+=($!)

    describe_k8s_resources &
    pid_array+=($!)

    describe_crs &
    pid_array+=($!)
  done

  for pid in "${pid_array[@]}"; do
    wait "${pid}"
  done

  if [[ $ARCHIVE == "true" ]]; then
    archive
  fi
}

function archive() {
  tar cvzf "$log_dir.tar.gz" -C "$log_dir" .
  if [[ $CLEANUP_LOOSE_FILES == "true" ]]; then
    rm -rf "${log_dir:?}"
  fi
}

function describe_nodes() {
  mkdir -p "$log_dir/nodes"
  nodes=$(kubectl get nodes -o go-template --template="{{ range .items }}{{ .metadata.name }} {{ end }}")
  for node in $nodes; do
    kubectl describe node "$node" > "$log_dir/nodes/$node.txt"
  done
}

function describe_resources() {
  kind=$1
  resources=$(kubectl get "$kind" -n "$namespace" -o go-template --template="{{ range .items }}{{ .metadata.name }} {{ end }}")
  for resource in $resources; do
    mkdir -p "$log_dir/$namespace/$kind/$resource"
    kubectl describe -n "$namespace" "$kind" "$resource" > "$log_dir/$namespace/$kind/$resource/$resource.txt"
  done
}

function container_logs() {
  pods=$(kubectl get pods -n "$namespace" -o go-template --template="{{ range .items }}{{ .metadata.name }} {{ end }}")
  for pod in $pods; do

    mkdir -p "$log_dir/$namespace/pods/$pod"

    init_containers=$(kubectl get pod -n "$namespace" "$pod" -o go-template --template="{{ range .spec.initContainers }}{{ .name }} {{ end }}")
    for container in $init_containers; do
      kubectl logs -n "$namespace" "$pod" -c "$container" > "$log_dir/$namespace/pods/$pod/$container.log"
    done

    containers=$(kubectl get pod -n "$namespace" "$pod" -o go-template --template="{{ range .spec.containers }}{{ .name }} {{ end }}")
    for container in $containers; do
      kubectl logs -n "$namespace" "$pod" -c "$container" > "$log_dir/$namespace/pods/$pod/$container.log"
    done
  done
}

function describe_k8s_resources() {
  describe_resources pods
  describe_resources jobs
  describe_resources cronjobs
  describe_resources deployments
  describe_resources daemonsets
  describe_resources statefulsets
  describe_resources configmaps
  describe_resources secrets
}

function describe_capi_resources() {
  describe_resources clusterclasses
  describe_resources clusterresourcesetbindings
  describe_resources clusterresourcesets
  describe_resources clusters
  describe_resources kubeadmconfigs
  describe_resources kubeadmconfigtemplates
  describe_resources kubeadmcontrolplanes
  describe_resources kubeadmcontrolplanetemplates
  describe_resources machinedeployments
  describe_resources machinehealthchecks
  describe_resources machinepools
  describe_resources machines
  describe_resources machinesets
  describe_resources providers
}

function describe_capm3_resources() {
  describe_resources metal3clusters
  describe_resources metal3dataclaims
  describe_resources metal3datas
  describe_resources metal3datatemplates
  describe_resources metal3machines
  describe_resources metal3machinetemplates
  describe_resources metal3remediations
  describe_resources metal3remediationtemplates
}

function describe_bmo_resources() {
  describe_resources baremetalhosts
  describe_resources firmwareschemas
  describe_resources hostfirmwaresettings
  describe_resources ipaddresses
  describe_resources ipclaims
  describe_resources ippools.ipam.metal3.io
  describe_resources preprovisioningimages
}

function describe_afo_resources() {
  describe_resources baremetalmachines
  describe_resources capiclusters
  describe_resources configs
  describe_resources nodepools
  describe_resources platformclusters
  describe_resources racks
  describe_resources virtualmachineactionpoweroffs
  describe_resources virtualmachineactionreimages
  describe_resources virtualmachineactionrestarts
  describe_resources virtualmachineactionstarts
  describe_resources virtualmachines
  describe_resources workloadnetworks
}

function describe_crs() {
  describe_capi_resources
  describe_capm3_resources
  describe_bmo_resources
  describe_afo_resources
}

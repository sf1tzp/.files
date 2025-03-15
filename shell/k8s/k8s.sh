#!/bin/bash

export PATH="$PATH:/usr/local/opt/kubernetes-cli/bin/"

alias k=kubectl
alias kc=kubectl
alias kx=kubectx

source <(kubectl completion bash)
complete -F __start_kubectl k
complete -F __start_kubectl kc

source <(helm completion bash)

function kstat {
    if [ -z "$1" ]; then
        namespace="-A"
    else
        namespace="-n $1"
    fi

    watch "kubectl get pods $namespace | grep -v 'Completed'"
}

function kerr {
    if [ -z "$1" ]; then
        namespace="-A"
    else
        namespace="-n $1"
    fi

    watch "kubectl get pods $namespace | grep -v 'Running\|Completed'"
}

function job_rerun {
  NS=$1
  JOB=$2
  if command -v jq; then
    JOB_JSON_ORIGINAL=$(mktemp --suffix=".json")
    kubectl get -n "$NS" jobs "$JOB" -o=json > "$JOB_JSON_ORIGINAL"
    JOB_JSON_RE_RUN=$(mktemp --suffix=".json")
    jq 'del(.status) | del(.metadata.creationTimestamp) | del(.metadata.labels."controller-uid") | del(.metadata.resourceVersion) | del(.metadata.selfLink) | del(.metadata.uid) | del(.spec.selector) | del(.spec.template.metadata.creationTimestamp) | del(.spec.template.metadata.labels."controller-uid" )' "$JOB_JSON_ORIGINAL" > "$JOB_JSON_RE_RUN"
    cat "$JOB_JSON_ORIGINAL" | kubectl delete -f -
    cat "$JOB_JSON_RE_RUN" | kubectl create -f -
  else
    echo "JQ not installed"
  fi
}

function aks-creds {
  RG=$1
  CLUSTER=$2
  az aks get-credentials --resource-group $RG --name $CLUSTER
}

function merge-kubeconfig {
  if [[ ! -f ~/.kube/config.bak ]]; then
    cp ~/.kube/config ~/.kube/config.bak
  fi
  new_config=$1
  KUBECONFIG=~/.kube/config:$new_config kubectl config view --flatten > ~/.kube/wtf
  chmod 600 ~/.kube/wtf
  mv ~/.kube/wtf ~/.kube/config
}

function reset-kubeconfig {
  if [[ -f ~/.kube/config.bak ]]; then
    cp ~/.kube/config.bak ~/.kube/config
  fi
}

function simulator-reset {
  rm ~/.ssh/known_hosts
  rm ~/.kube/bootstrap-kubeconfig.yaml
  rm ~/.kube/undercloud-kubeconfig.yaml
  reset-kubeconfig
}

function open-ephemeral {
  ssh rack1compute01 -- sudo iptables -A INPUT -p tcp --dport 6443 -j ACCEPT
}


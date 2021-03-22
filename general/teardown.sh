#!/usr/bin/env bash
function teardown() {
  [[ -n $1 ]] && status=$1 || status=0
  [[ -n $2 ]] && namespace=$2 || namespace="default"

  existing_chaos_engine=$(kubectl get chaosengine --n $namespace 2>/dev/null)
  if [[ -n "$existing_chaos_engine" ]]; then
    kubectl delete chaosengine --all -n $namespace
  fi
  if [[ $(kubectl delete -f https://litmuschaos.github.io/litmus/litmus-operator-v1.13.0.yaml &>/dev/null) -eq 0 ]]; then
    echo "Exiting with status: $status" && exit $status
  else
    echo "Failed to delete Litmus Resources. Please Delete it manually" && exit 1
  fi
}

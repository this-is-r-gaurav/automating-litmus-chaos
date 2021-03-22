#!/usr/bin/env bash
SCRIPT_PATH="$(realpath "$(dirname "$0")")"
source "$SCRIPT_PATH/teardown.sh"
# Add Helm Repo
if [[ -n "$1" ]]; then
  NAME_SPACE="$1" ;
  else
    NAME_SPACE=default;
    required_or_default NAME_SPACE "$NOT_REQUIRED" "$NAME_SPACE";
fi
if [[ $(helm repo add litmuschaos https://litmuschaos.github.io/litmus-helm/ &>/dev/null) -eq 0 ]]; then
  printf "Litmus Helm Repo Added\n"
else
  printf "Litmus Repo Failed to Add Helm Chart\n\n" &&
    teardown 1
fi
# Add Litmus NS
result=$(kubectl get ns litmus --no-headers 2>/dev/null)
if [[ -z $result ]]; then
  kubectl create ns litmus &>/dev/null
else
  status=$(echo "$result" | awk '{print $2}')
  if [[ "$status" != "Active" ]]; then
    printf "Namespace Litmus Exist, but in state %s\n\n" "$status"
    teardown 1
  fi
fi
# Add Litmus Chart to Litmus NS

litmus_pod="$(kubectl get pods -n litmus --no-headers 2>/dev/null)"
if [[ "$(kubectl get pods -n litmus --no-headers 2>/dev/null | awk '{print $3}' )" != "Running" ]];then
  helm install chaos litmuschaos/litmus --namespace=litmus &> /dev/null || (printf "Failed to Add Litmus Chart to Litmus Namespace" && teardown 1)
fi
#Verification
printf "Waiting For Pod Getting Ready."
waiting=20
while [ "$(kubectl get pods -n litmus --no-headers 2>/dev/null | awk '{print $3}' )" != "Running" ]; do
    printf "."
    (( waiting-- ))
    sleep 3
    if [[ $waiting -eq 0 ]]; then
      printf "Pod in litmus namespace not ready, please check cluster is working\n"
      teardown 1
    fi
done
printf "\n"

litmus_pod="$(kubectl get pods -n litmus --no-headers 2>/dev/null)"
if [[ -n "$litmus_pod" && $(echo "$litmus_pod" | wc -l) -eq 1 ]];then
   status="$(echo "$litmus_pod" | awk '{print $3}')"
   if [[ "$status" != "Running" ]];then
      printf "Status of Litmus Pod should be Running, but it is %s\n" "$status";
      teardown 1;
  else
    printf "Litmus Pod Ready\n"
   fi
fi
chaos_crd="$(kubectl get crds --no-headers | grep chaos)";
if [[ $(echo "$chaos_crd" | wc -l) -ne 3 ]];then
	printf "There must be 3 chaos CRDs, chaosengines.litmuschaos.io, chaosexperiments.litmuschaos.io, chaosresults.litmuschaos.io. Found %s CRDs\n" "$(echo "$chaos_crd" | wc -l)"
	teardown 1 "$NAME_SPACE";
	else
	  printf "CRD Ready\n"
fi

api_resources="$(kubectl api-resources --no-headers | grep chaos)"
if [[ $(echo "$api_resources" | wc -l) -ne 3 ]];then
	printf "There must be 3 api-resources, chaosengines, chaosexperiments, chaosresults. Found %s api-resources\n" "$(echo "$api_resources" | wc -l)"
	teardown 1 "$NAME_SPACE";
  else
    printf "API Resource Ready\n"
fi
"${SCRIPT_PATH}/setup_general_exp.sh" "$NAME_SPACE"
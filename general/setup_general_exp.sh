#!/usr/bin/env bash
BASE_PATH=$(dirname "$(realpath "$(dirname "$0")")")
#SCRIPT_PATH="$(realpath "$(dirname "$0")")"
source "${BASE_PATH}/utils/args_validator.sh"

if [[ -n "$1" ]]; then
    NAME_SPACE="$1" ;
  else
    NAME_SPACE=default
    required_or_default NAME_SPACE "$NOT_REQUIRED" "$NAME_SPACE";
fi
general_experiments=$(kubectl get chaosexperiments -n "$NAME_SPACE" --no-headers 2>/dev/null | wc -l)
if [[ "$general_experiments" -ne 23 ]]; then
  kubectl apply -f https://hub.litmuschaos.io/api/chaos/1.13.0?file=charts/generic/experiments.yaml -n "$NAME_SPACE" &> /dev/null
fi
general_experiments=$(kubectl get chaosexperiments -n "$NAME_SPACE" --no-headers 2>/dev/null | wc -l)
printf "%s chaosexperiments added\n" "$general_experiments"
#!/usr/bin/env bash
BASE_PATH=$(dirname "$(realpath "$(dirname "$0")")")
#SCRIPT_PATH="$(realpath "$(dirname "$0")")"
source "${BASE_PATH}/utils/args_validator.sh"
source "${BASE_PATH}/general/teardown.sh"

if [[ -n "$1" ]]; then APP_NAME="$1"; else required_or_default APP_NAME "$REQUIRED" "$APP_NAME"; fi
if [[ -n "$2" ]]; then APP_TYPE="$2"; else APP_TYPE=deployment && required_or_default APP_TYPE "$NOT_REQUIRED" "$APP_TYPE"; fi
if [[ -n "$3" ]]; then NAME_SPACE="$3" ; else NAME_SPACE=default && required_or_default NAME_SPACE "$NOT_REQUIRED" "$NAME_SPACE";fi
if [[ -n "$4" ]]; then SERVICE_ACCOUNT_NAME="$4" ; else SERVICE_ACCOUNT_NAME=node-restart-sa && required_or_default SERVICE_ACCOUNT_NAME "$NOT_REQUIRED" "$SERVICE_ACCOUNT_NAME";fi

kubectl apply -f "$BASE_PATH/templates/node-restart/rbac.yaml"

SERVICE_ACCOUNT=$(kubectl get sa "$SERVICE_ACCOUNT_NAME" -n "$NAME_SPACE" --no-headers)
if [[ $(echo "$SERVICE_ACCOUNT" | wc -l) -ne 1 ]]; then
  printf "Expected 1 service account, Found %s \n\n" "$(echo "$SERVICE_ACCOUNT" | wc -l)"
  teardown 1 "$NAME_SPACE"
fi

if [[ $(kubectl annotate "${APP_TYPE}" "${APP_NAME}" litmuschaos.io/chaos="true" -n "$NAME_SPACE" &>/dev/null) -eq 0 ]]; then
  printf "Application %s annotated \n\n" "$APP_TYPE/$APP_NAME";
else
  printf "Application %s can't be annotated  \n\n" "$APP_TYPE/$APP_NAME" && \
  teardown 1 "$NAME_SPACE"
fi

kubectl apply -f "$BASE_PATH/templates/node-restart/chaosengine.yaml" 2>/dev/null
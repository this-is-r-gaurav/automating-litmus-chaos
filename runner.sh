#!/usr/bin/env bash
BASE_PATH="$(realpath "$(dirname "$0")")"
SCRIPT_PATH="$BASE_PATH"

APP_NAME=$(yq e ".app_name" "$BASE_PATH/init.yaml")
APP_KIND=$(yq e ".app_kind" "$BASE_PATH/init.yaml")
APP_NAMESPACE=$(yq e ".app_namespace" "$BASE_PATH/init.yaml")
APP_LABEL=$(yq e ".app_label" "$BASE_PATH/init.yaml")
source "${BASE_PATH}/general/teardown.sh"
"${BASE_PATH}/general/setup.sh" "$APP_NAMESPACE"


PIPELINES=($(yq e ".chaos_pipeline[]" "$BASE_PATH/init.yaml"))
if [[ "${#PIPELINES[@]}" -gt 0 ]];then
  for pipeline in "${PIPELINES[@]}"
  do
  	if [[ -x ${BASE_PATH}/${pipeline}/runner.sh ]];then
  		if [[ $(realpath "${BASE_PATH}/${pipeline}/runner.sh") != $(realpath "$SCRIPT_PATH/runner.sh") ]]; then
  			"${BASE_PATH}/${pipeline}/runner.sh" "$APP_NAME" "$APP_KIND" "$APP_NAMESPACE" "$APP_LABEL"
  	    fi
  	else
  		printf "Warning: Either File %s/runner.sh not exist or doesn't have executable permission.\n\n" "${pipeline}"
  	fi
  done
fi

#teardown 0 "$APP_NAMESPACE"

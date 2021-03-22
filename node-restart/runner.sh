#!/usr/bin/env bash
BASE_PATH=$(dirname "$(realpath "$(dirname "$0")")")
SCRIPT_PATH="$(realpath "$(dirname "$0")")"

chaos_name='node-restart'
source "${BASE_PATH}/utils/args_validator.sh"
source "${BASE_PATH}/general/teardown.sh"
if [[ -n "$1" ]]; then APP_NAME="$1"; else required_or_default APP_NAME "$REQUIRED" "$APP_NAME"; fi
if [[ -n "$2" ]]; then APP_KIND="$2"; else APP_KIND=deployment && required_or_default APP_KIND "$NOT_REQUIRED" "$APP_KIND"; fi
if [[ -n "$3" ]]; then NAME_SPACE="$3" ; else NAME_SPACE=default && required_or_default NAME_SPACE "$NOT_REQUIRED" "$NAME_SPACE";fi
if [[ -n "$4" ]]; then APP_LABEL="$4" ; else APP_LABEL=default && required_or_default APP_LABEL "$NOT_REQUIRED" "$APP_LABEL";fi

CHAOS_CONFIG="$(yq e ".chaos_config[] | select(.name=\"$chaos_name\")" "$BASE_PATH/init.yaml")"
CHAOS_ANNOTATION_CHECK="$(echo "$CHAOS_CONFIG" | yq e ".annotation_check" -)"
CHAOS_NAME="$(echo "$CHAOS_CONFIG" | yq e ".name" -)"

SERVICE_ACCOUNT_NAME="$(echo "$CHAOS_CONFIG" | yq e ".service_account" -)"
AUXILIARY_APP_INFO="$(echo "$CHAOS_CONFIG" | yq e ".auxiliary_app_info" -)"

cp "$BASE_PATH/templates/node-restart/rbac.yaml.template" "$BASE_PATH/templates/node-restart/rbac.yaml"
sed -i -e "s/SERVICE_ACCOUNT_NAME_TEMPLATE/$SERVICE_ACCOUNT_NAME/g" -e "s/SERVICE_ACCOUNT_NAMESPACE_TEMPLATE/$NAME_SPACE/g" "$BASE_PATH/templates/node-restart/rbac.yaml"
experiment_template=$(awk 'NR>=22&&NR<=40' "$BASE_PATH/templates/node-restart/chaosengine.yaml.template")
cp "$BASE_PATH/templates/node-restart/chaosengine.yaml.template" "$BASE_PATH/templates/node-restart/chaosengine.yaml"

# CHAOS DETAIL REPLACE
sed -i -e "s/CHAOS_NAME_TEMPLATE/$CHAOS_NAME/g" -e "s/CHAOS_NAMESPACE_TEMPLATE/$NAME_SPACE/g" -e "s/CHAOS_ANNOTATION_CHECK_TEMPLATE/$CHAOS_ANNOTATION_CHECK/g" "$BASE_PATH/templates/node-restart/chaosengine.yaml"

sed -i "s/AUXILIARY_APP_INFO_TEMPLATE/$AUXILIARY_APP_INFO/g" "$BASE_PATH/templates/node-restart/chaosengine.yaml"

sed -i "s/CHAOS_SERVICE_ACCOUNT_TEMPLATE/$SERVICE_ACCOUNT_NAME/g" "$BASE_PATH/templates/node-restart/chaosengine.yaml"

sed -i -e "s/APP_NAMESPACE_TEMPLATE/$NAME_SPACE/g" -e "s%APP_LABEL_TEMPLATE%$APP_LABEL%g" -e "s/APP_KIND_TEMPLATE/$APP_KIND/g" "$BASE_PATH/templates/node-restart/chaosengine.yaml"

experiments=$(echo "$CHAOS_CONFIG" | yq e ".experiments" -)

experiment_name=($(echo "$experiments" | yq e '.[].name' -))
for index in "${!experiment_name[@]}";do
	EXPERIMENT_NAME=$(echo "$experiments" | yq e ".[$index].name" -)
	HOSTNAME=$(echo "$experiments" | yq e ".[$index].hostname" -)
	TARGET_NODE_NAME=$(echo "$experiments" | yq e ".[$index].target_node_name" -)
	TARGET_NODE_IP=$(echo "$experiments" | yq e ".[$index].target_node_ip" -)
	SSH_USER=$(echo "$experiments" | yq e ".[$index].ssh_user" -)
	if [[ $index -eq 0 ]]; then
		sed -i -e "s/EXPERIMENT_NAME_TEMPLATE/$EXPERIMENT_NAME/g" -e"s/HOSTNAME_TEMPLATE/$HOSTNAME/g" \
		-e "s/TARGET_NODE_NAME_TEMPLATE/$TARGET_NODE_NAME/g" -e "s/TARGET_NODE_INTERNAL_IP_TEMPLATE/$TARGET_NODE_IP/g" \
		-e "s/SSH_USER_TEMPLATE/$SSH_USER/g" "$BASE_PATH/templates/node-restart/chaosengine.yaml"
	else
		NEW_EXP=$(echo "$experiment_template" | sed -e "s/EXPERIMENT_NAME_TEMPLATE/$EXPERIMENT_NAME/g" \
		-e "s/HOSTNAME_TEMPLATE/$HOSTNAME/g" -e "s/TARGET_NODE_NAME_TEMPLATE/$TARGET_NODE_NAME/g" \
		-e "s/TARGET_NODE_INTERNAL_IP_TEMPLATE/$TARGET_NODE_IP/g" -e "s/SSH_USER_TEMPLATE/$SSH_USER/g" )
		echo "$NEW_EXP" >> "$BASE_PATH/templates/node-restart/chaosengine.yaml"
	fi
done

"$SCRIPT_PATH/experiment.sh" "$APP_NAME" "$APP_KIND" "$NAME_SPACE" "$SERVICE_ACCOUNT_NAME"
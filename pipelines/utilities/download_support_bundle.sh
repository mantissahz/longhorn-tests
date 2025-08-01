#!/usr/bin/env bash

source pipelines/utilities/kubeconfig.sh
source pipelines/utilities/longhorn_ui.sh

set -e

SUPPORT_BUNDLE_FILE_NAME=${1:-"lh-support-bundle.zip"}
SUPPORT_BUNDLE_ISSUE_URL=${2:-""}
SUPPORT_BUNDLE_ISSUE_DESC=${3:-"Auto-generated support bundle"}

set_kubeconfig
export_longhorn_ui_url

JSON_PAYLOAD="{\"issueURL\": \"${SUPPORT_BUNDLE_ISSUE_DESC}\", \"description\": \"${SUPPORT_BUNDLE_ISSUE_DESC}\"}"

CURL_CMD="curl -XPOST ${LONGHORN_CLIENT_URL}/v1/supportbundles -H 'Accept: application/json' -H 'Accept-Encoding: gzip, deflate' -d '"${JSON_PAYLOAD}"'"

SUPPORT_BUNDLE_URL=`kubectl exec -n longhorn-system svc/longhorn-frontend -- bash -c "${CURL_CMD}"  | jq -r '.links.self + "/" + .name'`

SUPPORT_BUNDLE_READY=false
while [[ ${SUPPORT_BUNDLE_READY} == false ]]; do
    PERCENT=`kubectl exec -n longhorn-system svc/longhorn-frontend -- curl -H 'Accept: application/json' ${SUPPORT_BUNDLE_URL} | jq -r '.progressPercentage' || true`
    echo ${PERCENT}
    
    if [[ ${PERCENT} == 100 ]]; then SUPPORT_BUNDLE_READY=true; fi
done

kubectl exec -n longhorn-system svc/longhorn-frontend -- curl -H 'Accept-Encoding: gzip, deflate' ${SUPPORT_BUNDLE_URL}/download > ${SUPPORT_BUNDLE_FILE_NAME}

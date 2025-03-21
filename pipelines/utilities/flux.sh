source pipelines/utilities/longhorn_status.sh


init_flux(){
  flux install
}


create_flux_helm_repo(){
  CHART_URL="${1:-${HELM_CHART_URL}}"
  flux create source helm longhorn --url "${CHART_URL}" --namespace "${LONGHORN_NAMESPACE}"
}


create_flux_helm_release(){
  CHART_VERSION="${1:-${HELM_CHART_VERSION}}"
  cat << EOF > /tmp/values.yaml
privateRegistry:
  createSecret: false
  registrySecret: docker-registry-secret
EOF
  flux create helmrelease longhorn --chart longhorn --source HelmRepository/longhorn --chart-version "${CHART_VERSION}" --namespace "${LONGHORN_NAMESPACE}" --values "/tmp/values.yaml"
  wait_longhorn_status_running
}
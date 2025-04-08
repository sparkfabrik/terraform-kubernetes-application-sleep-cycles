#!/usr/bin/env bash

# https://github.com/kubernetes-sigs/kind/releases
export KIND_VERSION="${KIND_VERSION:-0.27.0}"

KIND_BIN="$(command -v kind || true)"
export KIND_BIN

KIND_CLUSTER_NAME="application-sleep-cycles"
export KIND_CLUSTER_NAME

OS=$(uname | awk '{ print tolower($0) }')
echo "Detected OS: ${OS}"

ARCH="amd64"
if [ "$(uname -m)" = "arm64" ]; then
  ARCH="arm64"
fi
echo "Detected ARCH: ${ARCH}"

get_kind() {
  # shellcheck disable=SC2143
  if [ ! "${KIND_BIN}" ] || [ ! "$(${KIND_BIN} version | grep "${KIND_VERSION}")" ]; then
    [ "${CI}" = "true" ] && KIND_PATH="/usr/local/bin" || KIND_PATH="./bin"
    mkdir -p "${KIND_PATH}"
    curl -Lo "${KIND_PATH}/kind" "https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-${OS}-${ARCH}"
    chmod +x "${KIND_PATH}/kind"
    export KIND_BIN="${KIND_PATH}/kind"
  fi
}

create_kind_cluster() {
  local KUBE_VERSION KIND_CLUSTER_CONFIG KIND_NODE_VERSION KUBE_NAMESPACE CONFIG_OPT

  KIND_CLUSTER_CONFIG=${1:-}
  KUBE_VERSION="${2:-"1.31"}"
  KUBE_NAMESPACE="${KUBE_NAMESPACE:-default}"

  case $KUBE_VERSION in
  "1.32") KIND_NODE_VERSION="kindest/node:v1.32.2@sha256:f226345927d7e348497136874b6d207e0b32cc52154ad8323129352923a3142f" ;;
  "1.31") KIND_NODE_VERSION="kindest/node:v1.31.6@sha256:28b7cbb993dfe093c76641a0c95807637213c9109b761f1d422c2400e22b8e87" ;;
  "1.30") KIND_NODE_VERSION="kindest/node:v1.30.10@sha256:4de75d0e82481ea846c0ed1de86328d821c1e6a6a91ac37bf804e5313670e507" ;;
  "1.29") KIND_NODE_VERSION="kindest/node:v1.29.14@sha256:8703bd94ee24e51b778d5556ae310c6c0fa67d761fae6379c8e0bb480e6fea29" ;;
  *) echo "Unsupported Kubernetes version: ${KUBE_VERSION}" && exit 1 ;;
  esac

  get_kind

  echo -e "\nINFO: Using kind from \"${KIND_BIN}\" version \"$(${KIND_BIN} version)\"\n"
  echo "Using Kind node version: ${KIND_NODE_VERSION}"

  if [ ! "$(${KIND_BIN} get clusters | grep "${KIND_CLUSTER_NAME}")" ]; then
    echo "Cluster \"${KIND_CLUSTER_NAME}\" not found, creating it...."
    CONFIG_OPT=""
    if [ -n "${KIND_CLUSTER_CONFIG}" ]; then
      CONFIG_OPT="--config ${KIND_CLUSTER_CONFIG}"
    fi
    # shellcheck disable=SC2086
    "${KIND_BIN}" create cluster --name "${KIND_CLUSTER_NAME}" ${CONFIG_OPT} --wait 60s --image "${KIND_NODE_VERSION}"

    # Enforce the usage of the `default` namespace after the cluster creation.
    # https://github.com/kubernetes/kubernetes/issues/118693
    echo "Setting the namespace to: ${KUBE_NAMESPACE}"
    kubectl config set-context --current --namespace="${KUBE_NAMESPACE}"
  fi

  kubectl config current-context
  kubectl config set-context --current --namespace="default"
}

delete_kind_cluster() {
  get_kind

  if [ "$(${KIND_BIN} get clusters | grep "${KIND_CLUSTER_NAME}")" ]; then
    echo "Deleting cluster \"${KIND_CLUSTER_NAME}\"..."
    "${KIND_BIN}" delete cluster --name "${KIND_CLUSTER_NAME}"
  else
    echo "Cluster \"${KIND_CLUSTER_NAME}\" not found, skipping deletion."
  fi
}

generate_kubeconfig() {
  local KUBE_CONFIG_FILE="${1:-}"

  if [ -z "${KUBE_CONFIG_FILE}" ]; then
    echo "Kubeconfig file path is required."
    exit 1
  fi

  get_kind

  echo "Generating kubeconfig file: ${KUBE_CONFIG_FILE}"
  "${KIND_BIN}" get kubeconfig --name "${KIND_CLUSTER_NAME}" >"${KUBE_CONFIG_FILE}"
}

#!/usr/bin/env bash

DRY_RUN=${DRY_RUN:-0}
PROTECTED_NAMESPACES=${PROTECTED_NAMESPACES:-}

# Function to drain nodes
remove_terminating_pods() {
  local PODS POD POD_NAMESPACE POD_NAME

  PODS=$(kubectl get pod --all-namespaces | grep -i terminating | awk '{print $1","$2}')
  if [ -z "${PODS}" ]; then
    echo "No pods stuck in terminating state to remove."
    return 0
  fi

  for POD in ${PODS}; do
    POD_NAMESPACE=$(echo "${POD}" | cut -d',' -f1)
    POD_NAME=$(echo "${POD}" | cut -d',' -f2)

    echo "Removing pod in terminating state: ${POD_NAMESPACE}/${POD_NAME}"

    # Check if the namespace is protected
    if [ -n "${PROTECTED_NAMESPACES}" ] && [[ ",${PROTECTED_NAMESPACES}," == *",${POD_NAMESPACE},"* ]]; then
      echo "Skipping pod ${POD_NAME} in protected namespace ${POD_NAMESPACE}"
      continue
    fi

    # Dry run option
    if [ "${DRY_RUN}" -eq "1" ]; then
      echo "DRY-RUN: kubectl delete pod -n ${POD_NAMESPACE} --grace-period=0 --force --wait=false ${POD_NAME}"
      continue
    fi

    kubectl delete pod -n "${POD_NAMESPACE}" --grace-period=0 --force --wait=false "${POD_NAME}"
  done

  echo "All pods in terminating state are removed."
}

remove_terminating_pods

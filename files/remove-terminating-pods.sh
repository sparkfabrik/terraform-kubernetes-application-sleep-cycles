#!/bin/sh

DRY_RUN=${DRY_RUN:-0}
PROTECTED_NAMESPACES=${PROTECTED_NAMESPACES:-}

# Protected entries are shell glob patterns matched against the whole name:
# a plain name matches only itself, "*foo*" matches any name containing "foo".
is_protected_namespace() {
  ns="${1}"
  set -f
  for protected_ns in $(echo "${PROTECTED_NAMESPACES}" | tr "," " "); do
    # shellcheck disable=SC2254 # The pattern is intentionally unquoted to allow globs.
    case "${ns}" in
    ${protected_ns})
      set +f
      return 0
      ;;
    esac
  done
  set +f
  return 1
}

# Function to remove pods stuck in terminating state
remove_terminating_pods() {
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
    if is_protected_namespace "${POD_NAMESPACE}"; then
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

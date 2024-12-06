#!/usr/bin/env bash

DRY_RUN=${DRY_RUN:-0}
NAMESPACES=${NAMESPACES:-}
PROTECTED_NAMESPACES=${PROTECTED_NAMESPACES:-}
NAMESPACES_LABEL_SELECTOR=${NAMESPACES_LABEL_SELECTOR:-}
NAMESPACES_ALL_LABEL_SELECTOR=${NAMESPACES_ALL_LABEL_SELECTOR:-}
DEPLOYMENTS_LABEL_SELECTOR=${DEPLOYMENTS_LABEL_SELECTOR:-}
STATEFULSETS_LABEL_SELECTOR=${STATEFULSETS_LABEL_SELECTOR:-}
GO_TO_REPLICAS=${GO_TO_REPLICAS:-1}

filter_namespaces() {
  # Usage examples:
  # With warnings (default):
  # NAMESPACES=$(filter_namespaces "${PROTECTED_NAMESPACES}" "${NAMESPACES}")
  # Without warnings:
  # NAMESPACES=$(filter_namespaces "${PROTECTED_NAMESPACES}" "${NAMESPACES}" 1)
  local protected_namespaces="${1}"
  local namespaces_to_filter="${2}"
  local no_warning=${3:-0}
  local filtered_namespaces="${namespaces_to_filter}"
  local filtered_out=""

  for protected_ns in $(echo "${protected_namespaces}" | tr "," " "); do
    if echo "${filtered_namespaces}" | grep -q "${protected_ns}"; then
      filtered_out="${filtered_out}${protected_ns},"
      filtered_namespaces=$(echo "${filtered_namespaces}" | sed "s/${protected_ns}//g" | sed "s/,,/,/g" | sed "s/^,//" | sed "s/,$//")
    fi
  done
  # Show warning if any namespaces were filtered out
  if [ -n "${filtered_out}" ] && [ "${no_warning}" -eq 0 ]; then
    filtered_out=${filtered_out%,} # Remove trailing comma
    echo "WARNING: Following namespaces were filtered out: ${filtered_out}" >&2
  fi

  echo "${filtered_namespaces}"
}

scale_resources() {
  # Usage example:
  # scale_resources -n "${KUBE_NAMESPACE}" -r deployment -l "${DEPLOYMENTS_LABEL_SELECTOR}" -t "${GO_TO_REPLICAS}" -d "${DRY_RUN}"
  OPTIND=1

  local namespace=""
  local resource_type=""
  local label_selector=""
  local target_replicas=1
  local dry_run=0
  local selector_arg=""

  while getopts "n:r:l:t:d:" opt; do
    case $opt in
    n) namespace="$OPTARG" ;;
    r) resource_type="$OPTARG" ;;
    l) label_selector="$OPTARG" ;;
    t) target_replicas="$OPTARG" ;;
    d) dry_run="$OPTARG" ;;
    *)
      echo "Usage: scale_resources -n namespace -r resource_type [-l label_selector] -t target_replicas [-d dry_run]" >&2
      return 1
      ;;
    esac
  done

  if [ -z "$namespace" ] || [ -z "$resource_type" ]; then
    echo "Namespace and resource type are required" >&2
    return 1
  fi

  [ -n "$label_selector" ] && selector_arg="-l ${label_selector}"

  for resource in $(kubectl -n "${namespace}" get "${resource_type}" ${selector_arg} -o jsonpath='{.items[*].metadata.name}'); do
    echo "Processing ${resource_type}: ${namespace}/${resource}"

    if [ "${dry_run}" -eq "1" ]; then
      echo "DRY-RUN: kubectl -n ${namespace} scale --replicas ${target_replicas} ${resource_type} ${resource}"
      continue
    fi

    kubectl -n "${namespace}" scale --replicas "${target_replicas}" "${resource_type}" "${resource}" || {
      echo "Error scaling ${resource_type} ${resource}"
      return 1
    }
  done

  return 0
}

# Filter out protected namespaces
NAMESPACES=$(filter_namespaces "${PROTECTED_NAMESPACES}" "${NAMESPACES}")

# Get namespaces with label selector
LABELLED_NAMESPACES=""
if [ -n "${NAMESPACES_LABEL_SELECTOR}" ]; then
  LABELLED_NAMESPACES=$(kubectl get namespaces -l "${NAMESPACES_LABEL_SELECTOR}" -o jsonpath='{.items[*].metadata.name}')
  # Check if any of protected namespaces are in labelled namespace and remove it from labelled namespace list
  LABELLED_NAMESPACES=$(filter_namespaces "${PROTECTED_NAMESPACES}" "${LABELLED_NAMESPACES}")
  if [ -n "${NAMESPACES}" ] && [ -n "${LABELLED_NAMESPACES}" ]; then
    # If both NAMESPACES and LABELLED_NAMESPACES are set, merge them
    NAMESPACES="${NAMESPACES},${LABELLED_NAMESPACES}"
  elif [ -n "${LABELLED_NAMESPACES}" ]; then
    # If only LABELLED_NAMESPACES is set, use it
    NAMESPACES="${LABELLED_NAMESPACES}"
  fi
fi

# Get namespaces with label selector all
LABELLED_NAMESPACES_ALL=""
if [ -n "${NAMESPACES_ALL_LABEL_SELECTOR}" ]; then
  LABELLED_NAMESPACES_ALL=$(kubectl get namespaces -l "${NAMESPACES_LABEL_SELECTOR}","${NAMESPACES_ALL_LABEL_SELECTOR}" -o jsonpath='{.items[*].metadata.name}')
  # Check if any of protected namespaces are in labelled namespace and remove it from labelled namespace list
  WARNINGS=""
  LABELLED_NAMESPACES_ALL=$(filter_namespaces "${PROTECTED_NAMESPACES}" "${LABELLED_NAMESPACES_ALL}")
  if [ -n "$WARNINGS" ]; then
    printf "Filtering warnings:\n%b" "$WARNINGS" >&2
  fi
fi

if [ -z "${NAMESPACES}" ]; then
  echo "NAMESPACES variable is not set. Nothing to do."
  exit 0
fi

if [ -z "${DEPLOYMENTS_LABEL_SELECTOR}" ] && [ -z "${STATEFULSETS_LABEL_SELECTOR}" ] && [ -z "${LABELLED_NAMESPACES_ALL}" ]; then
  echo "DEPLOYMENTS_LABEL_SELECTOR or STATEFULSETS_LABEL_SELECTOR variable is not set. Nothing to do."
  exit 0
fi

echo "Involved namespaces: ${NAMESPACES}"
echo "Namespaces set for all resources management: ${LABELLED_NAMESPACES_ALL}"
echo "Deployments label selector: ${DEPLOYMENTS_LABEL_SELECTOR}"

# Filter out all resources namespace
NAMESPACES=$(filter_namespaces "${LABELLED_NAMESPACES_ALL}" "${NAMESPACES}" 1)

for KUBE_NAMESPACE in $(echo "${NAMESPACES}" | tr "," " "); do
  echo "Processing namespace: ${KUBE_NAMESPACE}"
  if [ -n "${DEPLOYMENTS_LABEL_SELECTOR}" ]; then
    scale_resources -n "${KUBE_NAMESPACE}" -r deployment -l "${DEPLOYMENTS_LABEL_SELECTOR}" -t "${GO_TO_REPLICAS}" -d "${DRY_RUN}"
  fi
  if [ -n "${STATEFULSETS_LABEL_SELECTOR}" ]; then
    scale_resources -n "${KUBE_NAMESPACE}" -r statefulset -l "${STATEFULSETS_LABEL_SELECTOR}" -t "${GO_TO_REPLICAS}" -d "${DRY_RUN}"
  fi
done

if [ -n "${LABELLED_NAMESPACES_ALL}" ]; then
  echo "Processing all labelled namespaces: ${LABELLED_NAMESPACES_ALL}"
  for KUBE_NAMESPACE in $(echo "${LABELLED_NAMESPACES_ALL}" | tr "," " "); do
    echo "Processing namespace: ${KUBE_NAMESPACE}"
    scale_resources -n "${KUBE_NAMESPACE}" -r deployment -t "${GO_TO_REPLICAS}" -d "${DRY_RUN}"
    scale_resources -n "${KUBE_NAMESPACE}" -r statefulset -t "${GO_TO_REPLICAS}" -d "${DRY_RUN}"
  done
fi

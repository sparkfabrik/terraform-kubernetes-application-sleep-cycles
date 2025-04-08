#!/usr/bin/env bash

DRY_RUN=${DRY_RUN:-0}
NODES_LABEL_SELECTORS=${NODES_LABEL_SELECTORS:-}

if [ -z "${NODES_LABEL_SELECTORS}" ]; then
  echo "NODES_LABEL_SELECTORS variable is not set. Nothing to do."
  exit 0
fi

# Function to drain nodes
drain_nodes() {
  local current_lbls
  for current_lbls in $(echo "${NODES_LABEL_SELECTORS}" | tr '|' ' '); do
    echo "Drain nodes matching label selector: ${current_lbls}"
    if [ "${DRY_RUN}" -eq "1" ]; then
      echo "DRY-RUN: kubectl drain --force --ignore-daemonsets -l ${current_lbls}"
      continue
    fi

    echo "Execute drain command: kubectl drain --force --ignore-daemonsets -l ${current_lbls}"
    kubectl drain --force --ignore-daemonsets -l "${current_lbls}"
    echo "Drained nodes matching label selector: ${current_lbls}"
  done

  return 0
}

drain_nodes

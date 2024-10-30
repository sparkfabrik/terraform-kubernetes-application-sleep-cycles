#!/usr/bin/env bash

DRY_RUN=${DRY_RUN:-0}
NAMESPACES=${NAMESPACES:-}
NAMESPACES_LABEL_SELECTOR=${NAMESPACES_LABEL_SELECTOR:-}
DEPLOYMENTS_LABEL_SELECTOR=${DEPLOYMENTS_LABEL_SELECTOR:-}
GO_TO_REPLICAS=${GO_TO_REPLICAS:-1}

# Get namespaces with label selector
LABELLED_NAMESPACES=""
if [ -n "${NAMESPACES_LABEL_SELECTOR}" ]; then
  LABELLED_NAMESPACES=$(kubectl get namespaces -l "${NAMESPACES_LABEL_SELECTOR}" -o jsonpath='{.items[*].metadata.name}')
  if [ -n "${NAMESPACES}" ] && [ -n "${LABELLED_NAMESPACES}" ]; then
    # If both NAMESPACES and LABELLED_NAMESPACES are set, merge them
    NAMESPACES="${NAMESPACES},${LABELLED_NAMESPACES}"
  elif [ -n "${LABELLED_NAMESPACES}" ]; then
    # If only LABELLED_NAMESPACES is set, use it
    NAMESPACES="${LABELLED_NAMESPACES}"
  fi
fi

if [ -z "${NAMESPACES}" ]; then
  echo "NAMESPACES variable is not set. Nothing to do."
  exit 0
fi

if [ -z "${DEPLOYMENTS_LABEL_SELECTOR}" ]; then
  echo "DEPLOYMENTS_LABEL_SELECTOR variable is not set. Nothing to do."
  exit 0
fi

echo "Involved namespaces: ${NAMESPACES}"
echo "Deployments label selector: ${DEPLOYMENTS_LABEL_SELECTOR}"

for KUBE_NAMESPACE in $(echo "${NAMESPACES}" | tr "," " "); do
  echo "Processing namespace: ${KUBE_NAMESPACE}"
  for DEPLOYMENT in $(kubectl -n "${KUBE_NAMESPACE}" get deployments -l "${DEPLOYMENTS_LABEL_SELECTOR}" -o jsonpath='{.items[*].metadata.name}'); do
    echo "Processing deployment: ${KUBE_NAMESPACE}/${DEPLOYMENT}"
    if [ "${DRY_RUN}" -eq "1" ]; then
      echo "DRY-RUN: kubectl -n ${KUBE_NAMESPACE} scale --replicas ${GO_TO_REPLICAS} deployment ${DEPLOYMENT}"
      continue
    fi
    echo "Scaling deployment ${KUBE_NAMESPACE}/${DEPLOYMENT} to ${GO_TO_REPLICAS} replicas"
    kubectl -n "${KUBE_NAMESPACE}" scale --replicas "${GO_TO_REPLICAS}" deployment "${DEPLOYMENT}"
  done
done

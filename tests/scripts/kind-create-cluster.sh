#!/usr/bin/env bash

set -e

BASE=$(dirname "${0}")
# Source the kind-function
# shellcheck disable=SC1091
. "${BASE}/kind.common.sh"

create_kind_cluster "${BASE}/kind-config.yaml"
